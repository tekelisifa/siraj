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

## Hauteur (pitch) et vitesse (rate) de chaque personnage pour la voix de synthèse.
const PROFILES := {
	"Le conteur": {"pitch": 0.78, "rate": 0.86},
	"L'enfant": {"pitch": 1.35, "rate": 1.0},
	"Selim": {"pitch": 1.25, "rate": 1.0},
	"Oumm Sâlih, la voisine": {"pitch": 1.12, "rate": 0.94},
	"": {"pitch": 0.85, "rate": 0.9},
}

var tts_voices: PackedStringArray = []
var _narration: AudioStreamPlayer
var _bbcode := RegEx.create_from_string("\\[[^\\]]*\\]")


func _init_voices() -> void:
	_narration = AudioStreamPlayer.new()
	add_child(_narration)
	if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		tts_voices = DisplayServer.tts_get_voices_for_language("fr")


## Identifiant stable d'une réplique (sert de nom au fichier enregistré).
static func line_id(who: String, text: String) -> String:
	return (who + "|" + text).md5_text().substr(0, 10)


func speak(who: String, text: String) -> void:
	stop_speech()
	if not Game.voice_on:
		return
	var path := VOICE_DIR + line_id(who, text) + ".ogg"
	if ResourceLoader.exists(path):
		_narration.stream = load(path)
		_narration.play()
		return
	if tts_voices.is_empty():
		return
	var p: Dictionary = PROFILES.get(who, PROFILES["Le conteur"])
	var voice := tts_voices[clampi(Game.voice_index, 0, tts_voices.size() - 1)]
	DisplayServer.tts_speak(_for_tts(text), voice, 90, float(p["pitch"]), float(p["rate"]))


func stop_speech() -> void:
	if _narration:
		_narration.stop()
	if not tts_voices.is_empty():
		DisplayServer.tts_stop()


func has_any_voice() -> bool:
	return not tts_voices.is_empty() or DirAccess.dir_exists_absolute(VOICE_DIR)


## Prépare le texte pour la synthèse : sans balises, avec la formule de salutation dite en entier.
func _for_tts(text: String) -> String:
	var t := _bbcode.sub(text, "", true)
	t = t.replace("ﷺ", ", sallallahou alayhi wa sallam,")
	t = t.replace("radiyAllâhu ʿanhu", "radiyallahou anhou")
	for c in ["ʿ", "ʾ", "«", "»", "(", ")"]:
		t = t.replace(c, "")
	return t


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
