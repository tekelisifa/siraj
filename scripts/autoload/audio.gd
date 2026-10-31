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
