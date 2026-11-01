#!/usr/bin/env python3
"""Génère les voix du jeu avec Chatterbox (multilingue, open source, licence MIT).

- Ne génère que ce qui manque : répliques nouvelles ou modifiées, voix de référence ajoutée
  ou changée, réglages modifiés. Les voix inutilisées sont supprimées.
- Les expressions arabes sont lues en mode arabe, le reste en français (data/phonetique.json).
- Voix de référence optionnelles : audio/voix/reference/<conteur|selim|enfant|voisine|passant>.<wav|mp3|ogg>
  et, pour les passages en arabe, la même voix enregistrée en arabe : <nom>_ar.<wav|mp3|ogg>
- Sans voix de référence, c'est la voix par défaut de Chatterbox (sans transposition :
  elle sonnait faux).
- « vitesse » accélère légèrement le débit sans changer la hauteur de la voix.

Usage :
  python3 tools/generer_voix.py                       # ce qui manque
  python3 tools/generer_voix.py --regenerer tout      # tout
  python3 tools/generer_voix.py --regenerer "Le conteur"
  python3 tools/generer_voix.py --regenerer fe62c74f8d,92b6351f15
  python3 tools/generer_voix.py --essai               # affiche le plan, sans générer
"""
import argparse
import copy
import hashlib
import inspect
import json
import subprocess
import sys
import tempfile
from pathlib import Path

from repliques import ROOT, lines, phonetics, split_languages

VOICE_DIR = ROOT / "audio" / "voix"
REF_DIR = VOICE_DIR / "reference"
MANIFEST = VOICE_DIR / "manifest.json"
VERSION = 2  # à augmenter pour tout régénérer après un changement de réglages

# Réglages par personnage.
#  ref : nom du fichier de voix de référence ; exag : intensité émotionnelle (0,5 = neutre) ;
#  cfg : fidélité au rythme du texte ; vitesse : débit (1,08 = 8 % plus rapide).
CHARACTERS = {
    "Le conteur": {"ref": "conteur", "exag": 0.5, "cfg": 0.5, "vitesse": 1.08},
    "Selim": {"ref": "selim", "exag": 0.6, "cfg": 0.5, "vitesse": 1.0},
    "L'enfant": {"ref": "enfant", "exag": 0.6, "cfg": 0.5, "vitesse": 1.0},
    "Oumm Nour, la voisine": {"ref": "voisine", "exag": 0.55, "cfg": 0.5, "vitesse": 1.0},
    "Un passant": {"ref": "passant", "exag": 0.5, "cfg": 0.5, "vitesse": 1.0},
}
# Narration et lieux découverts : voix du conteur, un peu plus douce.
NARRATOR = {"ref": "conteur", "exag": 0.45, "cfg": 0.5, "vitesse": 1.08}
PAUSE_S = 0.12


def settings(who: str) -> dict:
    return CHARACTERS.get(who, NARRATOR)


def reference(name: str):
    for ext in (".wav", ".mp3", ".ogg", ".flac", ".m4a"):
        p = REF_DIR / f"{name}{ext}"
        if p.exists():
            return p
    return None


def file_hash(p) -> str:
    return hashlib.sha1(p.read_bytes()).hexdigest()[:12] if p else ""


def fingerprint(who: str) -> str:
    s = settings(who)
    ref = reference(s["ref"])
    fp = f"v{VERSION}|{json.dumps(s, sort_keys=True)}|{file_hash(ref)}"
    ref_ar = reference(s["ref"] + "_ar")
    if ref_ar:
        fp += f"|ar:{file_hash(ref_ar)}"
    return fp


def plan(force: str):
    ph = phonetics()
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8")) if MANIFEST.exists() else {}
    all_lines = lines()
    wanted = {f.strip() for f in force.split(",") if f.strip()} if force else set()
    todo = []
    for scene, title, who, text, lid in all_lines:
        segs = split_languages(text, ph)
        if not segs:
            continue
        fp = fingerprint(who) + "|" + json.dumps(segs, ensure_ascii=False)
        path = VOICE_DIR / f"{lid}.ogg"
        forced = "tout" in wanted or lid in wanted or who in wanted
        recorded = path.exists() and lid not in manifest  # vrai enregistrement déposé à la main
        if forced or (not recorded and (not path.exists() or manifest.get(lid, {}).get("fp") != fp)):
            todo.append({"id": lid, "who": who, "text": text, "segs": segs, "fp": fp, "path": path})
    keep = {lid for *_, lid in all_lines}
    orphans = [p for p in VOICE_DIR.glob("*.ogg") if p.stem not in keep and p.stem in manifest]
    return todo, orphans, manifest


def load_model():
    import torch
    from chatterbox.mtl_tts import ChatterboxMultilingualTTS

    torch.set_num_threads(max(1, torch.get_num_threads()))
    kwargs = {"device": "cpu"}
    if "t3_model" in inspect.signature(ChatterboxMultilingualTTS.from_pretrained).parameters:
        kwargs["t3_model"] = "v3"
    print("Chargement de Chatterbox", kwargs, flush=True)
    return ChatterboxMultilingualTTS.from_pretrained(**kwargs)


def generate(model, item, default_conds):
    import torch

    s = settings(item["who"])
    ref = reference(s["ref"])
    model.conds = copy.deepcopy(default_conds)
    pieces = []
    silence = torch.zeros(1, int(model.sr * PAUSE_S))
    for i, (lang, seg) in enumerate(item["segs"]):
        args = {"text": seg, "language_id": lang, "exaggeration": s["exag"], "cfg_weight": s["cfg"]}
        ref_ar = reference(s["ref"] + "_ar") if lang == "ar" else None
        if ref_ar:
            # Même personnage, enregistré en arabe : prononciation arabe naturelle.
            args["audio_prompt_path"] = str(ref_ar)
        elif ref:
            args["audio_prompt_path"] = str(ref)
            if lang != "fr":
                args["cfg_weight"] = 0.0  # limite l'accent de la référence sur l'arabe
        wav = model.generate(**args)
        if i:
            pieces.append(silence)
        pieces.append(wav)
    return torch.cat(pieces, dim=1)


def save_ogg(wav, sr, dest: Path, speed: float = 1.0):
    import torchaudio

    with tempfile.TemporaryDirectory() as tmp:
        w = Path(tmp) / "voix.wav"
        torchaudio.save(str(w), wav, sr)
        subprocess.run([
            "ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(w),
            "-af", "silenceremove=start_periods=1:start_threshold=-45dB,areverse,silenceremove=start_periods=1:start_threshold=-45dB,areverse,"
            f"atempo={speed:.3f},loudnorm=I=-18:TP=-2",
            "-ac", "1", "-ar", "44100", "-c:a", "libvorbis", "-q:a", "5", str(dest),
        ], check=True)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--regenerer", default="", help="« tout », un personnage, ou des identifiants séparés par des virgules")
    ap.add_argument("--essai", action="store_true", help="affiche le plan sans générer")
    a = ap.parse_args()

    todo, orphans, manifest = plan(a.regenerer)
    print(f"{len(todo)} réplique(s) à générer, {len(orphans)} voix inutilisée(s) à supprimer.")
    for t in todo:
        segs = " + ".join(f"[{l}] {s}" for l, s in t["segs"])
        print(f"  {t['id']}  {t['who'] or 'Narration'} : {segs}")
    if a.essai:
        return 0

    for p in orphans:
        p.unlink()
        manifest.pop(p.stem, None)
    if todo:
        model = load_model()
        default_conds = copy.deepcopy(model.conds)
        for n, item in enumerate(todo, 1):
            print(f"[{n}/{len(todo)}] {item['id']} {item['who'] or 'Narration'}", flush=True)
            wav = generate(model, item, default_conds)
            save_ogg(wav, model.sr, item["path"], float(settings(item["who"]).get("vitesse", 1.0)))
            manifest[item["id"]] = {"qui": item["who"], "fp": item["fp"]}
            MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=1, sort_keys=True), encoding="utf-8")
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=1, sort_keys=True), encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
