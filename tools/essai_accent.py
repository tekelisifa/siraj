#!/usr/bin/env python3
"""Essai : prononciation arabe des prénoms et des formules.

Pour quelques répliques, produit deux versions à comparer :
- « avant » : la voix actuelle du jeu (audio/voix/<id>.ogg) ;
- « apres » : les passages arabes (prénoms, formules) sont lus par une voix arabe native
  (Microsoft Edge, ar-SA), puis convertis au timbre du personnage avec la conversion de voix
  de Chatterbox ; le français reste généré comme aujourd'hui.

Résultat dans essai/ (mp3). Usage : python3 tools/essai_accent.py
"""
import asyncio
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from repliques import ROOT, clean, line_id, phonetics, to_french_speech  # noqa: E402
import generer_voix as gv  # noqa: E402

OUT = ROOT / "essai"
LINES = [
    ("Le conteur", "Au matin, il les raconta au Prophète ﷺ. Celui-ci dit que c'était un rêve vrai, et qu'il fallait les apprendre à Bilal, dont la voix portait plus loin."),
    ("Oumm Nour, la voisine", "As-salâmu ʿalaykum, yâ Selîm ! Tu es bien matinal aujourd'hui."),
    ("Oumm Nour, la voisine", "[i](Elle baisse la voix.)[/i] As-tu entendu ce que l'on raconte ? Muhammad, fils de ʿAbdallâh ﷺ, celui que toute la Mecque appelle Al-Amîn…"),
    ("Selim", "Bismillâh… Mmm ! Alhamdulillâh !"),
]
# Prénoms ajoutés aux passages lus en arabe, pour l'essai.
EXTRA_ARABIC = [
    ["ʿAbdallâh", "عَبْدِ اللّٰهِ"],
    ["Muhammad", "مُحَمَّد"],
    ["Al-Amîn", "الْأَمِين"],
    ["Bilal", "بِلَال"],
]
EDGE_VOICE = {
    "Le conteur": ("ar-SA-HamedNeural", "-8%", "-6Hz"),
    "Selim": ("ar-SA-HamedNeural", "+0%", "+40Hz"),
    "Oumm Nour, la voisine": ("ar-SA-ZariyahNeural", "-5%", "+0Hz"),
}


def split(text, ph):
    """Comme repliques.split_languages, avec les prénoms en plus."""
    t = clean(text)
    arabic = sorted(ph["arabe"] + EXTRA_ARABIC, key=lambda p: -len(p[0]))
    parts, buf, i = [], "", 0
    while i < len(t):
        hit = next((p for p in arabic if t.startswith(p[0], i)), None)
        if hit:
            if buf.strip():
                parts.append(("fr", buf))
            buf = ""
            parts.append(("ar", hit[1]))
            i += len(hit[0])
        else:
            buf += t[i]
            i += 1
    if buf.strip():
        parts.append(("fr", buf))
    out = []
    for lang, seg in parts:
        if lang == "fr":
            seg = to_french_speech(seg, ph).strip(" ,;:")
            if not any(c.isalnum() for c in seg):
                continue
        out.append((lang, seg))
    # Regroupe les passages arabes qui se suivent (moins de coupures).
    merged = []
    for lang, seg in out:
        if merged and merged[-1][0] == lang == "ar":
            merged[-1] = ("ar", merged[-1][1] + " " + seg)
        else:
            merged.append((lang, seg))
    return merged


async def edge(text, voice, rate, pitch, dest):
    import edge_tts
    await edge_tts.Communicate(text, voice, rate=rate, pitch=pitch).save(str(dest))


def to_mp3(src, dest, speed=1.0):
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(src),
                    "-af", f"atempo={speed:.3f},loudnorm=I=-18:TP=-2", "-ac", "1", "-ar", "44100",
                    "-b:a", "128k", str(dest)], check=True)


def main():
    import torch
    import torchaudio
    import torchaudio.functional as AF
    from chatterbox.vc import ChatterboxVC

    OUT.mkdir(exist_ok=True)
    ph = phonetics()
    tts = gv.load_model()
    default_conds = gv.copy.deepcopy(tts.conds)
    vc = ChatterboxVC.from_pretrained("cpu")
    sr = tts.sr
    notes = []
    for n, (who, text) in enumerate(LINES, 1):
        slug = {"Le conteur": "conteur", "Selim": "selim"}.get(who, "voisine")
        lid = line_id(who, text)
        cur = ROOT / "audio" / "voix" / f"{lid}.ogg"
        if cur.exists():
            to_mp3(cur, OUT / f"{n}_{slug}_avant.mp3")
        s = gv.settings(who)
        ref = gv.reference(s["ref"])
        segs = split(text, ph)
        pieces = []
        silence = torch.zeros(1, int(sr * 0.12))
        with tempfile.TemporaryDirectory() as tmp:
            for i, (lang, seg) in enumerate(segs):
                if lang == "fr":
                    tts.conds = gv.copy.deepcopy(default_conds)
                    args = {"text": seg, "language_id": "fr", "exaggeration": s["exag"], "cfg_weight": s["cfg"]}
                    if ref:
                        args["audio_prompt_path"] = str(ref)
                    wav = tts.generate(**args)
                else:
                    voice, rate, pitch = EDGE_VOICE.get(who, EDGE_VOICE["Le conteur"])
                    src = Path(tmp) / f"ar{i}.mp3"
                    asyncio.run(edge(seg, voice, rate, pitch, src))
                    wav = vc.generate(str(src), target_voice_path=str(ref)) if ref else torchaudio.load(str(src))[0]
                    if wav.shape[0] > 1:
                        wav = wav.mean(0, keepdim=True)
                    wav_sr = vc.sr if ref else 24000
                    if wav_sr != sr:
                        wav = AF.resample(wav, wav_sr, sr)
                if pieces:
                    pieces.append(silence)
                pieces.append(wav)
            full = torch.cat(pieces, dim=1)
            w = Path(tmp) / "full.wav"
            torchaudio.save(str(w), full, sr)
            to_mp3(w, OUT / f"{n}_{slug}_apres.mp3", float(s.get("vitesse", 1.0)))
        notes.append(f"{n}. {who} : " + " + ".join(f"[{l}] {x}" for l, x in segs))
        print(notes[-1], flush=True)
    (OUT / "LISEZMOI.txt").write_text("\n".join(notes) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
