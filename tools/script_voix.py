#!/usr/bin/env python3
"""Génère audio/voix/SCRIPT.md : toutes les répliques du jeu, avec le nom du fichier
de chacune et le texte tel qu'il est dit.

Si une réplique change dans le code, son fichier change aussi : relancer ce script
(la génération automatique des voix le fait d'elle-même).

Usage : python3 tools/script_voix.py
"""
from repliques import ROOT, lines, phonetics, split_languages, clean

GUIDE = [
    "# Script des voix — Sirâj",
    "",
    "Chaque réplique correspond à un fichier `.ogg` de ce dossier, sous le nom indiqué.",
    "Le jeu l'utilise automatiquement à la place de la voix de synthèse du téléphone.",
    "",
    "Les fichiers sont générés automatiquement par GitHub (Chatterbox) ; on peut aussi",
    "remplacer n'importe lequel par un vrai enregistrement (mono, 44,1 kHz), sous le même nom.",
    "",
    "Fichier généré par `tools/script_voix.py` : ne pas modifier à la main.",
    "",
    "## Indications de jeu",
    "",
    "- **Le conteur** : un vieil homme, voix grave et chaleureuse, rythme lent, beaucoup de tendresse. Il revit ses souvenirs.",
    "- **Selim** (10 ans) : curieux, vif, un peu impressionné.",
    "- **L'enfant** (petit-fils du conteur) : voix d'enfant, attentive.",
    "- **Oumm Nour, la voisine** : bienveillante, maternelle ; elle baisse la voix quand elle raconte la nouvelle.",
    "- **Narration** et **lieux découverts** : dits par la voix du conteur, plus doucement.",
    "- Les passages en arabe sont lus en arabe (colonne « Dit »).",
    "",
    "## Voix de référence",
    "",
    "Pour donner un vrai timbre à un personnage, déposer un extrait de 10 à 20 secondes",
    "(une personne qui lit un texte, avec son accord) dans `audio/voix/reference/` :",
    "`conteur`, `selim`, `enfant`, `voisine` ou `passant`, en `.wav`, `.mp3` ou `.ogg`.",
    "Toutes les répliques du personnage sont alors régénérées avec ce timbre.",
]


def main() -> None:
    ph = phonetics()
    out = list(GUIDE)
    current = None
    for scene, title, who, text, lid in lines():
        if title != current:
            out += ["", f"## {title}", "", "| Fichier | Personnage | Réplique | Dit |", "|---|---|---|---|"]
            current = title
        said = " · ".join(f"[{lang}] {seg}" if lang == "ar" else seg for lang, seg in split_languages(text, ph))
        shown = clean(text).replace("|", "/")
        out.append(f"| `{lid}.ogg` | {who or 'Narration'} | {shown} | {said.replace('|', '/')} |")
    n = len(lines())
    out += ["", f"Total : {n} répliques.", ""]
    dest = ROOT / "audio" / "voix" / "SCRIPT.md"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text("\n".join(out), encoding="utf-8")
    print(f"{n} répliques → {dest.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
