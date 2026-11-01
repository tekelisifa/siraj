"""Répliques du jeu, communes au script d'enregistrement et au générateur de voix.

Les répliques sont lues directement dans le code des scènes (appels à say, show_text
et Audio.speak). Leur identifiant est calculé comme dans le jeu (Audio.line_id) :
les 10 premiers caractères du MD5 de « personnage|texte ».
"""
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCENES = [
    ("menu", "Menu"),
    ("veillee", "Épisode 1 · La veillée"),
    ("ch01_elephant", "Chapitre 1 · L'Année de l'Éléphant"),
    ("ch02_enfance", "Chapitre 2 · L'enfance"),
    ("mecque", "Épisode 1 · La Mecque, an 610"),
    ("medine", "Épisode 1 · Médine, le premier adhan"),
]
CALL = re.compile(r'(?:say_ref|say|show_text|speak)\(\s*"([^"]*)"\s*,\s*"([^"]*)"')
CONST = re.compile(r'const\s+(\w+)\s*:?=\s*"([^"]*)"')
CALL_CONST = re.compile(r'(?:say|show_text|speak)\(\s*"([^"]*)"\s*,\s*([A-Z_]+)\s*\)')
TAGS = re.compile(r"\[[^\]]*\]")
STAGE = re.compile(r"\([^)]*\)")


def line_id(who: str, text: str) -> str:
    return hashlib.md5(f"{who}|{text}".encode("utf-8")).hexdigest()[:10]


def lines():
    """Liste ordonnée et sans doublon de (scène, titre, personnage, texte, identifiant)."""
    seen = set()
    out = []
    for scene, title in SCENES:
        src = (ROOT / "scripts" / "scenes" / f"{scene}.gd").read_text(encoding="utf-8")
        consts = dict(CONST.findall(src))
        found = [(m.start(), m.group(1), m.group(2)) for m in CALL.finditer(src)]
        found += [(m.start(), m.group(1), consts[m.group(2)]) for m in CALL_CONST.finditer(src) if m.group(2) in consts]
        for _, who, text in sorted(found):
            text = text.replace("\\n", "\n")  # même chaîne qu'à l'exécution dans Godot
            lid = line_id(who, text)
            if lid in seen:
                continue
            seen.add(lid)
            out.append((scene, title, who, text, lid))
    return out


def phonetics():
    return json.loads((ROOT / "data" / "phonetique.json").read_text(encoding="utf-8"))


def clean(text: str) -> str:
    """Texte à dire : sans balises ni indications de jeu entre parenthèses."""
    return " ".join(STAGE.sub("", TAGS.sub("", text)).split())


def is_arabic_word(word: str, ph: dict) -> bool:
    """Mot translittéré de l'arabe (et pas un mot français comme « âge » ou « bâtie »)."""
    core = word.strip(".,;:!?…«»\"'()")
    if "ʿ" in core or "ʾ" in core:
        return True
    if not any(c in core for c in "âîûÂÎÛ"):
        return False
    return core[:1].isupper() or core.lower() in ph.get("particules", [])


def to_french_speech(text: str, ph: dict) -> str:
    """Même transformation que Audio.for_tts dans le jeu."""
    t = clean(text)
    for a, b in sorted(ph["mots"], key=lambda p: -len(p[0])):
        t = t.replace(a, b)
    words = []
    for w in t.split():
        if is_arabic_word(w, ph):
            for a, b in ph["lettres"]:
                w = w.replace(a, b)
        words.append(w)
    return " ".join(" ".join(words).replace("«", "").replace("»", "").split())


def split_languages(text: str, ph: dict):
    """Découpe une réplique en morceaux [("fr", ...), ("ar", ...)] : les expressions
    arabes connues sont lues en mode arabe, à partir du vrai texte arabe."""
    t = clean(text)
    arabic = sorted(ph["arabe"], key=lambda p: -len(p[0]))
    parts = []
    i = 0
    buf = ""
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
    return out
