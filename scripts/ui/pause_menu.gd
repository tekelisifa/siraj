class_name PauseMenu
extends CanvasLayer
## Menu de pause, présent dans chaque scène de l'histoire :
## - bouton en haut à droite ;
## - frise de la vie du Prophète ﷺ avec « Tu es ici » et l'âge de Selim ;
## - reprendre, recommencer la scène, revenir au menu, couper ou remettre la voix.
## Pendant l'adhan, le bouton disparaît (`locked`).

const SELIM_BIRTH := 600
const EVENTS := [
	[570, "Naissance"],
	[610, "Révélation"],
	[622, "Hégire"],
	[632, "Retour à Dieu"],
]


## « vers 570 » avant la Hijra (dates traditionnelles, approximatives),
## « an 3 de l'Hégire (625) » ensuite.
static func year_label(y: int) -> String:
	if y < 622:
		return "vers %d" % y
	if y == 622:
		return "an 1 de l'Hégire (622)"
	return "an %d de l'Hégire (%d)" % [y - 621, y]


static func selim_label(y: int) -> String:
	var age := y - SELIM_BIRTH
	if age <= 0:
		return "avant la naissance de Selim"
	return "Selim a environ %d ans" % age

var year := 610
var where := ""
var here_text := ""
var scene_path := ""
var locked := false:
	set(v):
		locked = v
		if _button:
			_button.visible = not v

var _button: Button
var _overlay: Control
var _voice_btn: Button
var _src_btn: Button


## Ajoute le menu de pause à une scène.
## `here` remplace la légende « Tu es ici · an … · Selim a … ans » de la frise.
static func attach(scene: Node, at_year: int, place: String, here := "") -> PauseMenu:
	var pm := PauseMenu.new()
	pm.year = at_year
	pm.where = place
	pm.here_text = here
	pm.scene_path = scene.scene_file_path
	scene.add_child(pm)
	return pm


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS

	_button = Button.new()
	_button.text = "II"
	_button.theme_type_variation = &"SecondaryButton"
	_button.focus_mode = Control.FOCUS_NONE
	_button.add_theme_font_size_override("font_size", 28)
	_button.anchor_left = 1.0
	_button.anchor_right = 1.0
	_button.offset_left = -116
	_button.offset_right = -24
	_button.offset_top = 30
	_button.offset_bottom = 110
	_button.tooltip_text = "Pause"
	_button.pressed.connect(open)
	add_child(_button)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(Game.NIGHT, 0.75)
	bg.border_color = Game.GOLD_LIGHT
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(22)
	_button.add_theme_stylebox_override("normal", bg)
	_button.add_theme_stylebox_override("hover", bg)
	_button.add_theme_stylebox_override("pressed", bg)
	_button.add_theme_color_override("font_color", Game.GOLD_LIGHT)

	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	add_child(_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(dim)

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Game.NIGHT
	sb.border_color = Game.GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(30)
	sb.set_content_margin_all(30)
	panel.add_theme_stylebox_override("panel", sb)
	panel.anchor_right = 1.0
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = 28
	panel.offset_right = -28
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_overlay.add_child(panel)

	var v := UI.vbox(18)
	panel.add_child(v)
	v.add_child(UI.label("Pause", 46, Game.GOLD_LIGHT, Game.font_title))
	v.add_child(UI.label(where, 26, Game.SAND))
	var frise := Frise.new()
	frise.year = year
	frise.label = here_text
	frise.custom_minimum_size = Vector2(0, 250)
	v.add_child(frise)

	_src_btn = UI.button("Sources de ce passage", false)
	_src_btn.pressed.connect(_show_sources)
	v.add_child(_src_btn)
	_src_btn.autowrap_mode = TextServer.AUTOWRAP_OFF
	_src_btn.custom_minimum_size = Vector2(0, 88)

	var resume := UI.button("Reprendre")
	resume.pressed.connect(close)
	v.add_child(resume)
	var restart := UI.button("Recommencer la scène", false)
	restart.pressed.connect(_restart)
	v.add_child(restart)
	var menu := UI.button("Revenir au menu", false)
	menu.pressed.connect(_to_menu)
	v.add_child(menu)
	_voice_btn = UI.button(Game.voice_mode_label(), false)
	_voice_btn.pressed.connect(_toggle_voice)
	v.add_child(_voice_btn)
	for b in [resume, restart, menu, _voice_btn]:
		(b as Button).autowrap_mode = TextServer.AUTOWRAP_OFF
		(b as Button).custom_minimum_size = Vector2(0, 88)


func open() -> void:
	if locked or Transition.busy:
		return
	Audio.stop_speech()
	_refresh_voice()
	_src_btn.visible = not Game.chapter_refs.is_empty()
	_src_btn.text = "Sources de ce passage (%d)" % Game.chapter_refs.size()
	_overlay.visible = true
	UI.fade_in(_overlay, 0.25)
	get_tree().paused = true


## Liste des références rencontrées : un toucher ouvre la fiche.
func _show_sources() -> void:
	var layer_root := Control.new()
	layer_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(layer_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer_root.add_child(dim)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Game.NIGHT
	sb.border_color = Game.GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(30)
	sb.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", sb)
	panel.anchor_right = 1.0
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = 28
	panel.offset_right = -28
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	layer_root.add_child(panel)
	var v := UI.vbox(12)
	panel.add_child(v)
	v.add_child(UI.label("Sources de ce passage", 40, Game.GOLD_LIGHT, Game.font_title))
	for k in Game.chapter_refs:
		var r := Game.ref(k)
		var b := UI.button("◆ %s" % r.get("court", k), false)
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		b.custom_minimum_size = Vector2(0, 80)
		b.add_theme_color_override("font_color", Game.ref_color(str(r.get("type", ""))))
		b.pressed.connect(func() -> void: RefCard.open(self, k))
		v.add_child(b)
	var note := UI.label(Game.FICTION_NOTE, 21, Game.MUTED)
	v.add_child(note)
	var back := UI.button("Retour")
	back.pressed.connect(layer_root.queue_free)
	v.add_child(back)


func close() -> void:
	_overlay.visible = false
	get_tree().paused = false


func _restart() -> void:
	close()
	Transition.go(scene_path, Game.NIGHT_DEEP)


func _to_menu() -> void:
	close()
	Transition.go("res://scenes/menu.tscn", Game.NIGHT_DEEP)


func _toggle_voice() -> void:
	Game.cycle_voice_mode()
	_refresh_voice()


func _refresh_voice() -> void:
	_voice_btn.text = Game.voice_mode_label()


## Frise de la vie du Prophète ﷺ, avec le moment de l'histoire.
class Frise extends Control:
	var year := 610
	var label := ""

	func _draw() -> void:
		var w := size.x
		var y := size.y * 0.5
		var x0 := 70.0
		var x1 := w - 70.0
		var fx := func(yr: float) -> float: return lerpf(x0, x1, (yr - 570.0) / (632.0 - 570.0))
		var here: float = fx.call(float(year))
		draw_line(Vector2(x0, y), Vector2(x1, y), Game.NIGHT_LINE, 6.0, true)
		draw_line(Vector2(x0, y), Vector2(here, y), Game.GOLD_LIGHT, 6.0, true)
		var font := Game.font_body
		for i in PauseMenu.EVENTS.size():
			var ev: Array = PauseMenu.EVENTS[i]
			var ex: float = fx.call(float(ev[0]))
			var past := int(ev[0]) <= year
			draw_circle(Vector2(ex, y), 12.0, Game.FLAME if past else Game.NIGHT_LINE)
			var up := i % 2 == 0
			var ty := y - 58.0 if up else y + 50.0
			var yl := ("vers %d" % int(ev[0])) if int(ev[0]) < 622 else str(ev[0])
			draw_string(font, Vector2(ex - 80.0, ty), yl, HORIZONTAL_ALIGNMENT_CENTER, 160.0, 22, Game.GOLD_LIGHT if past else Game.MUTED)
			draw_string(font, Vector2(ex - 80.0, ty + 28.0), str(ev[1]), HORIZONTAL_ALIGNMENT_CENTER, 160.0, 19, Game.SAND if past else Game.MUTED)
		# Tu es ici.
		draw_circle(Vector2(here, y), 20.0, Color(Game.FLAME, 0.3))
		draw_arc(Vector2(here, y), 22.0, 0.0, TAU, 40, Game.FLAME, 3.0, true)
		draw_circle(Vector2(here, y), 9.0, Game.FLAME_CORE)
		var text := label
		if text == "":
			text = "Tu es ici · %s" % PauseMenu.year_label(year)
		draw_string(Game.font_title, Vector2(0, size.y - 6.0), text, HORIZONTAL_ALIGNMENT_CENTER, w, 26, Game.FLAME)
