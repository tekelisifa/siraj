class_name DialogueBox
extends PanelContainer
## Boîte de dialogue narrative :
## - texte qui s'écrit progressivement (on touche pour accélérer, puis pour continuer) ;
## - puces de mots arabes à toucher pour découvrir leur sens (ajoutés au carnet) ;
## - choix du joueur.

signal advanced
signal choice_made(index: int)

var _speaker: Label
var _body: RichTextLabel
var _chips: HFlowContainer
var _trad: Label
var _choices: VBoxContainer
var _hint: Label
var _typing: Tween
var _waiting := false
var _has_choices := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Game.NIGHT, 0.93)
	sb.border_color = Game.NIGHT_LINE
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(30)
	sb.content_margin_left = 32
	sb.content_margin_right = 32
	sb.content_margin_top = 26
	sb.content_margin_bottom = 26
	add_theme_stylebox_override("panel", sb)

	var v := UI.vbox(14)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)

	_speaker = UI.label("", 24, Game.GOLD_LIGHT)
	_speaker.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(_speaker)

	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.fit_content = true
	_body.scroll_active = false
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_theme_font_override("normal_font", Game.font_title)
	_body.add_theme_font_override("bold_font", Game.font_title)
	_body.add_theme_font_override("italics_font", Game.font_arabic)
	_body.add_theme_font_size_override("normal_font_size", 36)
	_body.add_theme_font_size_override("bold_font_size", 36)
	_body.add_theme_font_size_override("italics_font_size", 34)
	_body.add_theme_color_override("default_color", Game.SAND)
	v.add_child(_body)

	_chips = HFlowContainer.new()
	_chips.add_theme_constant_override("h_separation", 12)
	_chips.add_theme_constant_override("v_separation", 12)
	v.add_child(_chips)

	_trad = UI.label("", 26, Game.TEAL_LIGHT)
	_trad.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_trad.visible = false
	v.add_child(_trad)

	_choices = UI.vbox(14)
	v.add_child(_choices)

	_hint = UI.label("Touche pour continuer", 20, Game.MUTED)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.modulate.a = 0.0
	v.add_child(_hint)


## Affiche une réplique et attend que le joueur touche l'écran.
## `words` : clés du lexique à proposer sous la réplique.
func say(who: String, text: String, words: Array = [], wait := true) -> void:
	show_text(who, text, words)
	if wait:
		_waiting = true
		await advanced


func show_text(who: String, text: String, words: Array = []) -> void:
	visible = true
	_speaker.text = who
	_speaker.visible = who != ""
	_body.text = text
	_body.visible_ratio = 0.0
	_trad.visible = false
	_clear(_chips)
	_clear(_choices)
	_has_choices = false
	for key in words:
		_add_chip(str(key))
	_chips.visible = words.size() > 0
	_hint.modulate.a = 0.0
	if _typing:
		_typing.kill()
	var dur := clampf(_body.get_parsed_text().length() * 0.028, 0.4, 3.2)
	_typing = create_tween()
	_typing.tween_property(_body, "visible_ratio", 1.0, dur)
	_typing.tween_callback(_show_hint)
	Audio.speak(who, text)
	_refit()


## Propose des choix et renvoie l'indice choisi.
func ask(options: Array) -> int:
	_clear(_choices)
	_has_choices = true
	_hint.modulate.a = 0.0
	for i in options.size():
		var b := UI.button(str(options[i]), i == 0)
		# Pas de retour à la ligne automatique : sinon Godot mesure le bouton avant de
		# connaître sa largeur (un mot par ligne) et le croit immense.
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.custom_minimum_size = Vector2(0, 96)
		b.pressed.connect(func() -> void: choice_made.emit(i))
		_choices.add_child(b)
		UI.fade_in(b, 0.4, 0.15 * i)
	_refit()
	var idx: int = await choice_made
	Audio.stop_speech()
	_has_choices = false
	_clear(_choices)
	_refit()
	return idx


## Ramène la boîte à sa taille utile. Un contrôle ancré grandit tout seul quand son
## contenu grandit, mais ne rétrécit jamais : on le force après chaque changement.
func _refit() -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	offset_top = offset_bottom


func _show_hint() -> void:
	if not _has_choices:
		create_tween().tween_property(_hint, "modulate:a", 1.0, 0.4)


func _add_chip(key: String) -> void:
	if not Game.LEXICON.has(key):
		return
	var entry: Dictionary = Game.LEXICON[key]
	var b := Button.new()
	b.theme_type_variation = &"ChipButton"
	b.focus_mode = Control.FOCUS_NONE
	b.text = "%s  ·  %s" % [entry["ar"], entry["lat"]]
	b.pressed.connect(func() -> void:
		_trad.text = "« %s »" % entry["fr"]
		_trad.visible = true
		UI.fade_in(_trad, 0.3)
		if Game.add_word(key):
			_trad.text += "   + carnet"
	)
	_chips.add_child(b)


func _clear(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if _typing and _typing.is_running():
			_typing.kill()
			_body.visible_ratio = 1.0
			_show_hint()
		elif _waiting and not _has_choices:
			_waiting = false
			Audio.stop_speech()
			advanced.emit()
