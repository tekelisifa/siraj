#!/usr/bin/env python3
"""Essai : voix d'Oumm Nour moins chuchotée.

Pour deux répliques, produit dans essai/ :
- 1_actuelle : la voix actuelle du jeu ;
- 2_expressive : même voix de référence, intensité de jeu poussée ;
- 3_par_defaut : sans voix de référence (voix féminine par défaut de Chatterbox).
Usage : python3 tools/essai_voisine.py
"""
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from repliques import ROOT, line_id, phonetics, split_languages  # noqa: E402
import generer_voix as gv  # noqa: E402

OUT = ROOT / "essai"
WHO = "Oumm Nour, la voisine"
LINES = [
    "As-salâmu ʿalaykum, yâ Selîm ! Tu es bien matinal aujourd'hui.",
    "Tiens, prends ces dattes. Et n'oublie pas de dire Bismillâh avant de manger.",
]
VARIANTS = {
    "2_expressive": {"ref": "voisine", "exag": 0.9, "cfg": 0.5, "vitesse": 1.0},
    "3_par_defaut": {"ref": "aucune", "exag": 0.6, "cfg": 0.5, "vitesse": 1.0},
}


def to_mp3(src, dest):
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(src),
                    "-af", "loudnorm=I=-18:TP=-2", "-ac", "1", "-ar", "44100", "-b:a", "128k", str(dest)], check=True)


def main():
    import torchaudio

    OUT.mkdir(exist_ok=True)
    ph = phonetics()
    model = gv.load_model()
    default_conds = gv.copy.deepcopy(model.conds)
    for n, text in enumerate(LINES, 1):
        cur = ROOT / "audio" / "voix" / f"{line_id(WHO, text)}.ogg"
        if cur.exists():
            to_mp3(cur, OUT / f"voisine_{n}_1_actuelle.mp3")
        for name, settings in VARIANTS.items():
            gv.CHARACTERS[WHO] = settings
            item = {"who": WHO, "segs": split_languages(text, ph)}
            wav = gv.generate(model, item, default_conds)
            with tempfile.TemporaryDirectory() as tmp:
                w = Path(tmp) / "v.wav"
                torchaudio.save(str(w), wav, model.sr)
                to_mp3(w, OUT / f"voisine_{n}_{name}.mp3")
            print(n, name, flush=True)


if __name__ == "__main__":
    main()
