extends Node2D
## Écran d'accueil : la lampe, le titre, le carnet de mots et le choix de la langue.

var time := 0.0
var _toast: Label
var _carnet: PanelContainer
var _carnet_list: VBoxContainer
var _carnet_btn: Button


func _ready() -> void:
	Audio.set_ambience("wind", 0.25)
	var root := UI.layer(self)
	var vs := get_viewport_rect().size

	var title := UI.vbox(0)
	UI.dock_top(title, 40, int(vs.y * 0.235))
	root.add_child(title)
	title.add_child(UI.label("سِرَاج", 72, Game.GOLD_LIGHT, Game.font_arabic))
	title.add_child(UI.label("Sirâj", 104, Game.SAND, Game.font_title))
	title.add_child(UI.label("Le voyage de Selim", 42, Game.GOLD_LIGHT, Game.font_title))
	var sub := UI.label("La vie du Prophète Muhammad ﷺ, racontée par un témoin", 26, Game.MUTED)
	title.add_child(sub)
	UI.fade_in(title, 1.0)

	var buttons := UI.vbox(18)
	UI.dock_bottom(buttons, 48, 56)
	root.add_child(buttons)

	var start := UI.button("Commencer le voyage")
	start.pressed.connect(func() -> void: Transition.go("res://scenes/veillee.tscn", Game.NIGHT_DEEP, "Épisode 1\nLe murmure"))
	buttons.add_child(start)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	buttons.add_child(row)
	_carnet_btn = UI.button("", false)
	_carnet_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_carnet_btn.pressed.connect(_toggle_carnet)
	row.add_child(_carnet_btn)
	var replay := UI.button("Revoir l'ouverture", false)
	replay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	replay.pressed.connect(func() -> void: Transition.go("res://scenes/intro.tscn", Game.NIGHT_DEEP))
	row.add_child(replay)
	_refresh_carnet_btn()

	var langs := HBoxContainer.new()
	langs.alignment = BoxContainer.ALIGNMENT_CENTER
	langs.add_theme_constant_override("separation", 12)
	buttons.add_child(langs)
	for l in [["Français", true], ["Türkçe", false], ["العربية", false]]:
		var b := UI.button(str(l[0]), bool(l[1]))
		b.custom_minimum_size = Vector2(180, 72)
		b.add_theme_font_size_override("font_size", 24)
		if not l[1]:
			b.pressed.connect(_show_toast.bind("Bientôt disponible"))
		langs.add_child(b)

	buttons.add_child(UI.label("Sources authentiques · relu par [NOM DU RELECTEUR]", 20, Color("a79c86")))
	UI.fade_in(buttons, 1.0, 0.4)

	_toast = UI.label("", 26, Game.NIGHT)
	_toast.modulate.a = 0.0
	UI.dock_top(_toast, 120, 60)
	root.add_child(_toast)

	_build_carnet(root)


func _build_carnet(root: Control) -> void:
	_carnet = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Game.NIGHT, 0.97)
	sb.border_color = Game.GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(30)
	sb.set_content_margin_all(32)
	_carnet.add_theme_stylebox_override("panel", sb)
	_carnet.anchor_right = 1.0
	_carnet.anchor_bottom = 1.0
	_carnet.offset_left = 32
	_carnet.offset_right = -32
	_carnet.offset_top = 120
	_carnet.offset_bottom = -120
	_carnet.visible = false
	root.add_child(_carnet)

	var v := UI.vbox(18)
	_carnet.add_child(v)
	v.add_child(UI.label("Mon carnet de mots", 48, Game.GOLD_LIGHT, Game.font_title))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_carnet_list = UI.vbox(20)
	_carnet_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_carnet_list)
	var close := UI.button("Fermer", false)
	close.pressed.connect(_toggle_carnet)
	v.add_child(close)


func _toggle_carnet() -> void:
	_carnet.visible = not _carnet.visible
	if not _carnet.visible:
		return
	for c in _carnet_list.get_children():
		c.queue_free()
	if Game.words.is_empty():
		_carnet_list.add_child(UI.label("Ton carnet est encore vide. Pendant l'histoire, touche les mots arabes pour les découvrir.", 28, Game.MUTED))
	for key in Game.words:
		var e: Dictionary = Game.LEXICON[key]
		var item := UI.vbox(2)
		item.add_child(UI.label(str(e["ar"]), 46, Game.GOLD_LIGHT, Game.font_arabic))
		item.add_child(UI.label(str(e["lat"]), 30, Game.SAND, Game.font_title))
		item.add_child(UI.label(str(e["fr"]), 24, Game.MUTED))
		_carnet_list.add_child(item)
	UI.fade_in(_carnet, 0.3)


func _refresh_carnet_btn() -> void:
	_carnet_btn.text = "Carnet de mots (%d)" % Game.words.size()


func _show_toast(text: String) -> void:
	_toast.text = text
	var bg := StyleBoxFlat.new()
	bg.bg_color = Game.GOLD_LIGHT
	bg.set_corner_radius_all(20)
	bg.set_content_margin_all(14)
	_toast.add_theme_stylebox_override("normal", bg)
	var tw := create_tween()
	tw.tween_property(_toast, "modulate:a", 1.0, 0.25)
	tw.tween_interval(1.4)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.4)


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	var vs := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vs), Game.NIGHT)
	Art.star_pattern(self, Rect2(0, 0, vs.x, vs.y * 0.3), 72.0, Color(0.79, 0.64, 0.29, 0.18))
	var flicker := sin(time * 7.0) * 0.5 + sin(time * 11.3) * 0.5
	Art.lantern(self, Vector2(vs.x * 0.5, vs.y * 0.05 + sin(time * 0.8) * 4.0), 1.0, 1.0, flicker)
