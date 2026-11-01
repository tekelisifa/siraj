extends Node
## État global du jeu : palette, polices, thème, sauvegarde et carnet de mots.

signal word_added(key: String)

# --- Palette « nuit, or et sable » ---
const NIGHT := Color("0e1a2b")
const NIGHT_DEEP := Color("0b1524")
const NIGHT_BLUE := Color("1e3350")
const NIGHT_LINE := Color("3a4c66")
const GOLD := Color("c9a24a")
const GOLD_LIGHT := Color("e8c877")
const FLAME := Color("f2c462")
const FLAME_CORE := Color("fff3d1")
const SAND := Color("f3e6cc")
const SAND_WARM := Color("f6d9a0")
const INK := Color("2a1d0c")
const MUTED := Color("c8bba0")
const TEAL := Color("2f7f7a")
const TEAL_LIGHT := Color("8fd3c7")

const SAVE_PATH := "user://siraj.cfg"

## Lexique des mots arabes que le joueur peut découvrir.
const LEXICON := {
	"salam": {"ar": "السَّلَامُ عَلَيْكُمْ", "lat": "As-salâmu ʿalaykum", "fr": "Que la paix soit sur toi"},
	"wa_salam": {"ar": "وَعَلَيْكُمُ السَّلَامُ", "lat": "Wa ʿalaykumu s-salâm", "fr": "Et sur toi la paix"},
	"bismillah": {"ar": "بِسْمِ اللّٰهِ", "lat": "Bismillâh", "fr": "Au nom de Dieu"},
	"alhamdulillah": {"ar": "الْحَمْدُ لِلّٰهِ", "lat": "Alhamdulillâh", "fr": "Louange à Dieu"},
	"jaddi": {"ar": "جَدِّي", "lat": "Jaddî", "fr": "Mon grand-père"},
	"iqra": {"ar": "اقْرَأْ", "lat": "Iqraʾ", "fr": "Lis ! (on traduit aussi : Récite !)"},
	"amin": {"ar": "الْأَمِين", "lat": "Al-Amîn", "fr": "Le digne de confiance"},
	"allahu_akbar": {"ar": "اللّٰهُ أَكْبَرُ", "lat": "Allâhu akbar", "fr": "Dieu est le plus grand"},
	"adhan": {"ar": "الْأَذَان", "lat": "Al-adhân", "fr": "L'appel à la prière"},
	"nour": {"ar": "نُور", "lat": "Nûr", "fr": "La lumière"},
	"kaaba": {"ar": "الْكَعْبَة", "lat": "Al-Kaʿba", "fr": "La Kaaba, la maison de Dieu"},
	"tamr": {"ar": "تَمْر", "lat": "Tamr", "fr": "Des dattes"},
	"zamzam": {"ar": "زَمْزَم", "lat": "Zamzam", "fr": "La source de Zamzam"},
	"jamal": {"ar": "جَمَل", "lat": "Jamal", "fr": "Le chameau"},
	"fil": {"ar": "الْفِيل", "lat": "Al-Fîl", "fr": "L'éléphant (nom d'une sourate du Coran)"},
	"ghanam": {"ar": "غَنَم", "lat": "Ghanam", "fr": "Les moutons"},
	"badiya": {"ar": "الْبَادِيَة", "lat": "Al-Bâdiya", "fr": "Le désert, la vie des nomades"},
	"umm": {"ar": "أُمّ", "lat": "Umm", "fr": "La mère"},
	"hajar_aswad": {"ar": "الْحَجَرُ الْأَسْوَد", "lat": "Al-Hajar al-Aswad", "fr": "La Pierre noire, à l'angle de la Kaaba"},
	"tijara": {"ar": "تِجَارَة", "lat": "Tijâra", "fr": "Le commerce"},
	"nadhir": {"ar": "نَذِير", "lat": "Nadhîr", "fr": "Celui qui avertit"},
	"safa": {"ar": "الصَّفَا", "lat": "As-Safâ", "fr": "Une petite colline près de la Kaaba"},
}

## Les 21 chapitres : numéro, titre, période, scène (vide = pas encore disponible).
## Le chapitre 13 est jouable en aperçu.
const CHAPTERS := [
	[1, "L'Année de l'Éléphant", "vers 570", "res://scenes/ch01_elephant.tscn"],
	[2, "L'enfance", "vers 570-583", "res://scenes/ch02_enfance.tscn"],
	[3, "Al-Amîn", "vers 595-605", "res://scenes/ch03_amin.tscn"],
	[4, "La lumière de Hira", "vers 610", "res://scenes/mecque.tscn"],
	[5, "L'appel sur as-Safâ", "vers 610-613", "res://scenes/ch05_safa.tscn"],
	[6, "Ahad, Ahad", "vers 613-615", ""],
	[7, "Les migrations en Abyssinie", "vers 615-616", ""],
	[8, "Les années difficiles", "vers 616-619", ""],
	[9, "Le voyage nocturne", "avant la Hijra", ""],
	[10, "Les serments d'al-ʿAqaba", "vers 621-622", ""],
	[11, "La Hijra", "an 1 (622)", ""],
	[12, "La mosquée et les frères", "an 1 (622)", ""],
	[13, "L'appel", "an 1 (622)", "res://scenes/medine.tscn"],
	[14, "La qibla et Badr", "an 2 (624)", ""],
	[15, "Ouhoud", "an 3 (625)", ""],
	[16, "La tranchée", "an 5 (627)", ""],
	[17, "Al-Houdaybiya", "an 6 (628)", ""],
	[18, "Les lettres aux souverains", "vers l'an 6-7", ""],
	[19, "Le retour à la Mecque", "an 8 (630)", ""],
	[20, "Le pèlerinage d'adieu", "an 10 (632)", ""],
	[21, "La lampe ne s'éteint pas", "an 11 (632)", ""],
]

## Phrase permanente du carnet : les personnages inventés.
const FICTION_NOTE := "Selim, sa famille et Oumm Nour sont des personnages inventés pour accompagner le récit. Ils ne sont pas des témoins de l'époque."

## Références (Coran, hadiths, Sîra) affichées discrètement pendant le jeu : data/references.json.
var references := {}
## Références rencontrées dans la scène en cours (page « Sources » du menu de pause).
var chapter_refs: Array[String] = []

var font_body: FontFile
var font_title: FontFile
var font_arabic: FontFile
var theme: Theme

var sound_ack := false
var subtitles := true
## Voix : "ia" (voix générées, sinon voix du téléphone), "telephone" (toujours la voix
## du téléphone) ou "off".
var voice_mode := "ia"
var voice_on: bool:
	get:
		return voice_mode != "off"
var storyteller_voices: Array[String] = []
var storyteller_choice := 2
var words: Array[String] = []
## Chapitres terminés (numéros).
var done_chapters: Array[int] = []


func _ready() -> void:
	_load_fonts()
	_build_theme()
	# Les interfaces vivent dans des CanvasLayer (sous des Node2D), qui ne transmettent pas
	# le thème de la fenêtre : on enrichit donc directement le thème par défaut du moteur.
	ThemeDB.get_default_theme().merge_with(theme)
	ThemeDB.fallback_font = font_body
	ThemeDB.fallback_font_size = 30
	get_tree().root.theme = theme
	_load_references()
	load_game()


func _load_references() -> void:
	var f := FileAccess.open("res://data/references.json", FileAccess.READ)
	if f:
		var d: Variant = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			references = d


func ref(key: String) -> Dictionary:
	return references.get(key, {})


func note_ref(key: String) -> void:
	if key != "" and references.has(key) and not key in chapter_refs:
		chapter_refs.append(key)


## Couleur du repère selon le type de source.
static func ref_color(kind: String) -> Color:
	match kind:
		"coran":
			return GOLD_LIGHT
		"hadith":
			return TEAL_LIGHT
		"sira":
			return SAND_WARM
	return MUTED


func _load_fonts() -> void:
	font_arabic = load("res://fonts/Amiri-Regular.ttf")
	font_title = load("res://fonts/Amiri-Bold.ttf")
	font_body = load("res://fonts/WorkSans.ttf")
	# Work Sans n'a pas de glyphes arabes ni le ﷺ : Amiri prend le relais.
	font_body.fallbacks = [font_arabic]
	font_title.fallbacks = [font_arabic]


func _box(bg: Color, border: Color = Color.TRANSPARENT, radius := 28, border_w := 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	sb.anti_aliasing = true
	return sb


func _build_theme() -> void:
	theme = Theme.new()
	theme.default_font = font_body
	theme.default_font_size = 30

	theme.set_color("font_color", "Label", SAND)

	# Bouton principal : or sur nuit.
	theme.set_stylebox("normal", "Button", _box(GOLD))
	theme.set_stylebox("hover", "Button", _box(GOLD_LIGHT))
	theme.set_stylebox("pressed", "Button", _box(GOLD.darkened(0.15)))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_stylebox("disabled", "Button", _box(NIGHT_LINE))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		theme.set_color(c, "Button", NIGHT)
	theme.set_font_size("font_size", "Button", 32)

	# Bouton secondaire : contour.
	theme.set_type_variation("SecondaryButton", "Button")
	theme.set_stylebox("normal", "SecondaryButton", _box(Color(0, 0, 0, 0), Color("5a6b82"), 28, 2))
	theme.set_stylebox("hover", "SecondaryButton", _box(Color(1, 1, 1, 0.05), GOLD_LIGHT, 28, 2))
	theme.set_stylebox("pressed", "SecondaryButton", _box(Color(1, 1, 1, 0.1), GOLD_LIGHT, 28, 2))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		theme.set_color(c, "SecondaryButton", SAND)

	# Puce de mot arabe : on la touche pour découvrir sa traduction.
	theme.set_type_variation("ChipButton", "Button")
	var chip := _box(Color(GOLD, 0.15), GOLD_LIGHT, 18, 2)
	chip.content_margin_top = 10
	chip.content_margin_bottom = 10
	chip.content_margin_left = 18
	chip.content_margin_right = 18
	theme.set_stylebox("normal", "ChipButton", chip)
	theme.set_stylebox("hover", "ChipButton", chip)
	theme.set_stylebox("pressed", "ChipButton", _box(Color(GOLD, 0.35), GOLD_LIGHT, 18, 2))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		theme.set_color(c, "ChipButton", GOLD_LIGHT)
	theme.set_font_size("font_size", "ChipButton", 28)

	theme.set_stylebox("background", "ProgressBar", _box(NIGHT_LINE, Color.TRANSPARENT, 6))
	theme.set_stylebox("fill", "ProgressBar", _box(GOLD_LIGHT, Color.TRANSPARENT, 6))


# --- Voix ---

const VOICE_MODES := ["ia", "telephone", "off"]


func cycle_voice_mode() -> void:
	var i := VOICE_MODES.find(voice_mode)
	voice_mode = VOICE_MODES[(i + 1) % VOICE_MODES.size()]
	save_game()
	Audio.stop_speech()


func voice_mode_label() -> String:
	match voice_mode:
		"ia":
			return "Voix : conteur IA"
		"telephone":
			return "Voix : téléphone"
	return "Voix : coupée"


# --- Carnet de mots ---

func add_word(key: String) -> bool:
	if key in words or not LEXICON.has(key):
		return false
	words.append(key)
	save_game()
	word_added.emit(key)
	Input.vibrate_handheld(30)
	return true


# --- Chapitres ---

static func chapter(n: int) -> Array:
	for c in CHAPTERS:
		if int(c[0]) == n:
			return c
	return []


## Légende de transition : « Chapitre 3 » puis le titre.
static func chapter_caption(n: int) -> String:
	var c := chapter(n)
	return "Chapitre %d\n%s" % [n, c[1]] if not c.is_empty() else ""


func go_chapter(n: int, color: Color = SAND_WARM) -> void:
	var c := chapter(n)
	if c.is_empty() or str(c[3]) == "":
		return
	Transition.go(str(c[3]), color, chapter_caption(n))


func mark_done(n: int) -> void:
	if not n in done_chapters:
		done_chapters.append(n)
		save_game()


## Chapitre suivant jouable (après n), ou 0.
static func next_playable(n: int) -> int:
	for c in CHAPTERS:
		if int(c[0]) > n and str(c[3]) != "" and int(c[0]) != 13:
			return int(c[0])
	return 0


# --- Sauvegarde ---

func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("options", "sound_ack", sound_ack)
	cfg.set_value("options", "subtitles", subtitles)
	cfg.set_value("options", "voice_mode", voice_mode)
	cfg.set_value("options", "storyteller_voices", storyteller_voices)
	cfg.set_value("options", "storyteller_choice", storyteller_choice)
	cfg.set_value("progress", "words", words)
	cfg.set_value("progress", "chapters", done_chapters)
	cfg.save(SAVE_PATH)


func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	sound_ack = cfg.get_value("options", "sound_ack", false)
	subtitles = cfg.get_value("options", "subtitles", true)
	voice_mode = str(cfg.get_value("options", "voice_mode", "ia"))
	storyteller_choice = cfg.get_value("options", "storyteller_choice", 2)
	var sv: Array = cfg.get_value("options", "storyteller_voices", [])
	storyteller_voices.clear()
	for v in sv:
		storyteller_voices.append(str(v))
	var ch: Array = cfg.get_value("progress", "chapters", [])
	done_chapters.clear()
	for c in ch:
		done_chapters.append(int(c))
	var saved: Array = cfg.get_value("progress", "words", [])
	words.clear()
	for w in saved:
		words.append(str(w))
