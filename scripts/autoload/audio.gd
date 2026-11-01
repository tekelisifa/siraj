extends Node
## Son du jeu.
## - Ambiances générées en temps réel (vent du désert, feu de la veillée) en attendant
##   de vrais enregistrements.
## - Lecture des fichiers audio (voix du conteur, adhan) s'ils sont présents dans res://audio/.

const MIX_RATE := 11025.0

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var voice: AudioStreamPlayer

var _mode := ""
var _target := 0.0
var _vol := 0.0
var _brown := 0.0
var _pop := 0.0
var _lp := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	gen.buffer_length = 0.25
	_player.stream = gen
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback

	voice = AudioStreamPlayer.new()
	add_child(voice)
	_init_voices()
	_init_sfx()


## Ambiances : "wind", "fire", "town" ou "" pour le silence.
func set_ambience(mode: String, volume := 0.4) -> void:
	_mode = mode
	_target = volume if mode != "" else 0.0


func _process(_delta: float) -> void:
	if _playback == null:
		return
	var frames := _playback.get_frames_available()
	for i in frames:
		_vol += (_target - _vol) * 0.0004
		var white := randf() * 2.0 - 1.0
		_brown = clampf(_brown + white * 0.02, -1.0, 1.0) * 0.997
		var s := _brown * 0.7
		if _mode == "fire":
			if randf() < 0.0015:
				_pop = randf_range(0.4, 1.0)
			_pop *= 0.97
			_lp = _lp * 0.6 + white * 0.4
			s = _brown * 0.35 + _lp * _pop * 0.8
		elif _mode == "town":
			_lp = _lp * 0.95 + white * 0.05
			s = _brown * 0.4 + _lp * 0.6
		_playback.push_frame(Vector2(s, s) * _vol)


# --- Voix des personnages ---
# 1. Si un enregistrement existe pour la réplique (res://audio/voix/<id>.ogg), on le joue.
# 2. Sinon, la voix de synthèse du téléphone lit la réplique, avec une hauteur et un
#    rythme propres à chaque personnage.
# La liste des répliques et de leurs identifiants est dans audio/voix/SCRIPT.md
# (générée par tools/script_voix.py).

const VOICE_DIR := "res://audio/voix/"
const PHONETIC_FILE := "res://data/phonetique.json"
## Voix retenues pour le conteur, dans la liste des voix françaises du téléphone de référence
## (numéros 8, 12 et 19 du menu, la 19 par défaut). Leur nom est mémorisé au premier lancement.
const STORYTELLER_PICKS := [7, 11, 18]
const STORYTELLER_DEFAULT := 2

## Hauteur (pitch) et vitesse (rate) de chaque personnage pour la voix de synthèse.
const PROFILES := {
	"Le conteur": {"pitch": 0.9, "rate": 0.86},
	"L'enfant": {"pitch": 1.35, "rate": 1.0},
	"Selim": {"pitch": 1.28, "rate": 1.0},
	"Oumm Nour, la voisine": {"pitch": 1.15, "rate": 0.94},
	"Un passant": {"pitch": 1.0, "rate": 1.0},
	"": {"pitch": 0.92, "rate": 0.9},
}

var tts_voices: PackedStringArray = []
var _voice_names := {}
var _narration: AudioStreamPlayer
var _bbcode := RegEx.create_from_string("\\[[^\\]]*\\]")
## Indications de jeu entre parenthèses, comme « (Elle baisse la voix.) » : jamais lues.
var _stage := RegEx.create_from_string("\\([^)]*\\)")
var _words: Array = []
var _letters: Array = []
var _particles: Array = []


func _init_voices() -> void:
	_narration = AudioStreamPlayer.new()
	add_child(_narration)
	_load_phonetics()
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return
	tts_voices = DisplayServer.tts_get_voices_for_language("fr")
	for v in DisplayServer.tts_get_voices():
		_voice_names[str(v.get("id", ""))] = str(v.get("name", ""))
	# Au premier lancement, on mémorise les voix choisies par leur identifiant :
	# l'ordre de la liste peut changer, l'identifiant non.
	if Game.storyteller_voices.is_empty() and tts_voices.size() > STORYTELLER_PICKS.max():
		for i in STORYTELLER_PICKS:
			Game.storyteller_voices.append(tts_voices[i])
		Game.storyteller_choice = STORYTELLER_DEFAULT
		Game.save_game()


func _load_phonetics() -> void:
	var raw := FileAccess.get_file_as_string(PHONETIC_FILE)
	var data = JSON.parse_string(raw)
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("Phonétique introuvable : " + PHONETIC_FILE)
		return
	_words = data.get("mots", [])
	_words.sort_custom(func(a, b) -> bool: return str(a[0]).length() > str(b[0]).length())
	_letters = data.get("lettres", [])
	_particles = data.get("particules", [])


## Voix proposées pour le conteur (celles retenues, sinon toutes les voix françaises).
func storyteller_candidates() -> PackedStringArray:
	var out := PackedStringArray()
	for id in Game.storyteller_voices:
		if id in tts_voices:
			out.append(id)
	return out if not out.is_empty() else tts_voices


func current_voice() -> String:
	var c := storyteller_candidates()
	if c.is_empty():
		return ""
	return c[clampi(Game.storyteller_choice, 0, c.size() - 1)]


func voice_label(id: String) -> String:
	var n: String = _voice_names.get(id, "")
	return n if n != "" else id


## Identifiant stable d'une réplique (sert de nom au fichier enregistré).
static func line_id(who: String, text: String) -> String:
	return (who + "|" + text).md5_text().substr(0, 10)


func speak(who: String, text: String) -> void:
	stop_speech()
	if not Game.voice_on:
		return
	var path := VOICE_DIR + line_id(who, text) + ".ogg"
	if Game.voice_mode == "ia" and ResourceLoader.exists(path):
		_narration.stream = load(path)
		_narration.play()
		return
	var voice := current_voice()
	if voice == "":
		return
	var p: Dictionary = PROFILES.get(who, PROFILES["Le conteur"])
	DisplayServer.tts_speak(for_tts(text), voice, 90, float(p["pitch"]), float(p["rate"]))


func is_speaking() -> bool:
	return _narration.playing or DisplayServer.tts_is_speaking()


func stop_speech() -> void:
	if _narration:
		_narration.stop()
	if not tts_voices.is_empty():
		DisplayServer.tts_stop()


## Prépare le texte pour la synthèse : sans balises ni indications de jeu, avec les mots
## arabes écrits « à la française » (data/phonetique.json), puis sans accents arabes
## (â, î, û, ʿ…) — seulement sur les mots arabes, pour ne pas abîmer « âge » ou « bâtie ».
func for_tts(text: String) -> String:
	var t := _bbcode.sub(text.replace("\n", " "), "", true)
	t = _stage.sub(t, "", true)
	for pair in _words:
		t = t.replace(str(pair[0]), str(pair[1]))
	var out := PackedStringArray()
	for w in t.split(" ", false):
		if _is_arabic_word(w):
			for pair in _letters:
				w = w.replace(str(pair[0]), str(pair[1]))
		out.append(w)
	return " ".join(out).replace("«", "").replace("»", "").strip_edges()


func _is_arabic_word(word: String) -> bool:
	var core := word.strip_edges().lstrip(".,;:!?…«»\"'()").rstrip(".,;:!?…«»\"'()")
	if "ʿ" in core or "ʾ" in core:
		return true
	var has_long := false
	for c in ["â", "î", "û", "Â", "Î", "Û"]:
		if c in core:
			has_long = true
	if not has_long:
		return false
	var first := core.substr(0, 1)
	return first == first.to_upper() and first != first.to_lower() or core.to_lower() in _particles


## Joue un fichier s'il existe. Retourne sa durée en secondes (0 si absent).
func play_file(path: String, volume_db := 0.0) -> float:
	if not ResourceLoader.exists(path):
		return 0.0
	var stream: AudioStream = load(path)
	voice.stream = stream
	voice.volume_db = volume_db
	voice.play()
	return stream.get_length()


func stop_voice() -> void:
	voice.stop()


# --- Bruitages générés (en attendant de vrais enregistrements) ---

const SFX_RATE := 22050
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx := {}


func _init_sfx() -> void:
	for i in 4:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_players.append(p)
	_sfx["pas"] = _wav(_burst(0.11, 0.12, 0.25))
	_sfx["ailes"] = _wav(_flutter(0.7))
	_sfx["decouverte"] = _wav(_whoosh(0.7))


## Joue un bruitage : "pas", "ailes" ou "decouverte".
func sfx(sound: String, volume_db := -8.0, pitch := 1.0) -> void:
	if not _sfx.has(sound):
		return
	for p in _sfx_players:
		if not p.playing:
			p.stream = _sfx[sound]
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return


func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = SFX_RATE
	w.stereo = false
	w.data = data
	return w


## Bruit filtré qui décroît vite : un pas dans le sable.
func _burst(dur: float, alpha: float, decay: float) -> PackedFloat32Array:
	var n := int(SFX_RATE * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		lp += alpha * ((randf() * 2.0 - 1.0) - lp)
		out[i] = lp * exp(-float(i) / (n * decay)) * 3.0
	return out


## Battements d'ailes : bouffées de bruit rapides.
func _flutter(dur: float) -> PackedFloat32Array:
	var n := int(SFX_RATE * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / SFX_RATE
		lp += 0.25 * ((randf() * 2.0 - 1.0) - lp)
		var beat := pow(maxf(0.0, sin(t * TAU * 11.0)), 6.0)
		out[i] = lp * beat * (1.0 - t / dur) * 2.2
	return out


## Souffle doux qui monte puis retombe : on découvre quelque chose.
func _whoosh(dur: float) -> PackedFloat32Array:
	var n := int(SFX_RATE * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / n
		var alpha := lerpf(0.02, 0.35, sin(t * PI))
		lp += alpha * ((randf() * 2.0 - 1.0) - lp)
		out[i] = lp * sin(t * PI) * 1.6
	return out
