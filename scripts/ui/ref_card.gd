class_name RefCard
extends CanvasLayer
## Fiche d'une référence (verset, hadith, Sîra…), ouverte en touchant un repère.
## Elle ne met pas le jeu en pause : un toucher n'importe où la referme.

var key := ""
var _root: Control


static func open(from: Node, ref_key: String) -> void:
	var card := RefCard.new()
	card.key = ref_key
	from.get_tree().current_scene.add_child(card)


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	var r := Game.ref(key)
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.gui_input.connect(_on_input)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	var kind := str(r.get("type", ""))
	var col := Game.ref_color(kind)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Game.NIGHT, 0.97)
	sb.border_color = col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(28)
	sb.set_content_margin_all(30)
	panel.add_theme_stylebox_override("panel", sb)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.anchor_right = 1.0
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = 36
	panel.offset_right = -36
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_root.add_child(panel)

	var v := UI.vbox(14)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(v)
	var kinds := {"coran": "Coran", "hadith": "Hadith", "sira": "Biographie (Sîra)", "reconstitution": "Reconstitution", "fiction": "Fiction"}
	var tag := UI.label(str(kinds.get(kind, "Source")).to_upper(), 20, col)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(tag)
	var title := UI.label(str(r.get("titre", "")), 30, Game.SAND, Game.font_title)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(title)
	var body := UI.label(str(r.get("texte", "")), 27, Game.SAND)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(body)
	var degree := UI.label(str(r.get("degre", "")), 22, Game.MUTED)
	degree.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(degree)
	var close_hint := UI.label("Touche pour fermer", 20, Game.MUTED)
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(close_hint)
	UI.fade_in(_root, 0.2)


func _on_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_root.accept_event()
		queue_free()
