#!/usr/bin/env python3
"""Génère audio/voix/SCRIPT.md : toutes les répliques du jeu, avec le nom du fichier
à enregistrer pour chacune.

Le nom est calculé comme dans le jeu (Audio.line_id) : les 10 premiers caractères
du MD5 de « personnage|texte ». Si une réplique change dans le code, son fichier change
aussi : il faut alors relancer ce script et réenregistrer la réplique.

Usage : python3 tools/script_voix.py
"""
import hashlib
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCENES = ["veillee", "mecque", "aube"]
TITLES = {
    "veillee": "Épisode 1 · La veillée",
    "mecque": "Épisode 1 · La Mecque, an 610",
    "aube": "Épisode 1 · Médine, à l'aube",
}
CALL = re.compile(r'(?:say|show_text)\(\s*"([^"]*)"\s*,\s*"([^"]*)"')
SAMPLE = ("Le conteur", "Approche, mon petit. Je vais te raconter ce que mes yeux ont vu.")
TAGS = re.compile(r"\[[^\]]*\]")


def line_id(who: str, text: str) -> str:
    return hashlib.md5(f"{who}|{text}".encode("utf-8")).hexdigest()[:10]


def row(who: str, text: str) -> str:
    shown = TAGS.sub("", text).replace("|", "/").replace("\n", " ")
    return f"| `{line_id(who, text)}.ogg` | {who or 'Narration'} | {shown} |"


def main() -> None:
    out = [
        "# Script des voix — Sirâj",
        "",
        "Chaque réplique s'enregistre dans un fichier `.ogg` (mono, 44,1 kHz) déposé dans ce dossier,",
        "sous le nom indiqué. Le jeu l'utilise automatiquement à la place de la voix de synthèse.",
        "",
        "Fichier généré par `tools/script_voix.py` : ne pas modifier à la main.",
        "",
        "## Indications de jeu",
        "",
        "- **Le conteur** : un vieil homme, voix grave et chaleureuse, rythme lent, beaucoup de tendresse. Il revit ses souvenirs.",
        "- **Selim** (10 ans) : curieux, vif, un peu impressionné.",
        "- **L'enfant** (petit-fils du conteur) : voix d'enfant, attentive.",
        "- **Oumm Sâlih, la voisine** : bienveillante, maternelle ; elle baisse la voix quand elle raconte la nouvelle.",
        "- **Narration** (texte en italique) : dite par la voix du conteur, plus doucement.",
        "- Les mots arabes se prononcent à l'arabe (*As-salâmu ʿalaykum*, *Iqraʾ*…).",
        "- Après le nom du Prophète, dire *sallallâhu ʿalayhi wa sallam* en entier.",
        "",
        "## Menu",
        "",
        "| Fichier | Personnage | Réplique |",
        "|---|---|---|",
        row(*SAMPLE),
    ]
    total = 1
    for scene in SCENES:
        src = (ROOT / "scripts" / "scenes" / f"{scene}.gd").read_text(encoding="utf-8")
        lines = CALL.findall(src)
        out += ["", f"## {TITLES[scene]}", "", "| Fichier | Personnage | Réplique |", "|---|---|---|"]
        out += [row(w, t) for w, t in lines]
        total += len(lines)
    out += ["", f"Total : {total} répliques.", ""]
    dest = ROOT / "audio" / "voix" / "SCRIPT.md"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text("\n".join(out), encoding="utf-8")
    print(f"{total} répliques → {dest.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
