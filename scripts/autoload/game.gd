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
	"iqra": {"ar": "اقْرَأْ", "lat": "Iqraʾ", "fr": "Lis !"},
	"amin": {"ar": "الْأَمِين", "lat": "Al-Amîn", "fr": "Le digne de confiance"},
	"allahu_akbar": {"ar": "اللّٰهُ أَكْبَرُ", "lat": "Allâhu akbar", "fr": "Dieu est le plus grand"},
	"adhan": {"ar": "الْأَذَان", "lat": "Al-adhân", "fr": "L'appel à la prière"},
	"nour": {"ar": "نُور", "lat": "Nûr", "fr": "La lumière"},
	"kaaba": {"ar": "الْكَعْبَة", "lat": "Al-Kaʿba", "fr": "La Kaaba, la maison de Dieu"},
	"tamr": {"ar": "تَمْر", "lat": "Tamr", "fr": "Des dattes"},
	"zamzam": {"ar": "زَمْزَم", "lat": "Zamzam", "fr": "La source de Zamzam"},
	"jamal": {"ar": "جَمَل", "lat": "Jamal", "fr": "Le chameau"},
}

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


func _ready() -> void:
	_load_fonts()
	_build_theme()
	# Les interfaces vivent dans des CanvasLayer (sous des Node2D), qui ne transmettent pas
	# le thème de la fenêtre : on enrichit donc directement le thème par défaut du moteur.
	ThemeDB.get_default_theme().merge_with(theme)
	ThemeDB.fallback_font = font_body
	ThemeDB.fallback_font_size = 30
	get_tree().root.theme = theme
	load_game()


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


# --- Sauvegarde ---

func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("options", "sound_ack", sound_ack)
	cfg.set_value("options", "subtitles", subtitles)
	cfg.set_value("options", "voice_mode", voice_mode)
	cfg.set_value("options", "storyteller_voices", storyteller_voices)
	cfg.set_value("options", "storyteller_choice", storyteller_choice)
	cfg.set_value("progress", "words", words)
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
	var saved: Array = cfg.get_value("progress", "words", [])
	words.clear()
	for w in saved:
		words.append(str(w))
