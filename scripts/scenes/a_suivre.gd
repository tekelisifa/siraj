extends Node2D
## Écran « À suivre » : les chapitres déjà jouables, ceux qui arrivent, et un aperçu
## du chapitre 13 (le premier adhan), proposé à part pour ne pas sauter douze ans d'histoire.

const CHAPITRES := [
	["1", "L'Année de l'Éléphant", true],
	["2", "L'enfance", true],
	["3", "Al-Amîn", true],
	["4", "La lumière de Hira", true],
	["5", "L'appel sur as-Safâ", true],
	["6 à 12", "Des épreuves de la Mecque à l'arrivée à Médine", false],
	["13", "L'appel (aperçu disponible)", true],
	["14 à 21", "Médine, jusqu'au pèlerinage d'adieu", false],
]

var time := 0.0


func _ready() -> void:
	Audio.set_ambience("wind", 0.2)
	var root := UI.layer(self)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Game.NIGHT, 0.95)
	sb.border_color = Game.GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(30)
	sb.set_content_margin_all(30)
	panel.add_theme_stylebox_override("panel", sb)
	panel.anchor_right = 1.0
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = 30
	panel.offset_right = -30
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_child(panel)
	var v := UI.vbox(14)
	panel.add_child(v)
	v.add_child(UI.label("À suivre", 54, Game.GOLD_LIGHT, Game.font_title))
	v.add_child(UI.label("La suite du voyage arrive chapitre après chapitre.", 26, Game.SAND))
	for c in CHAPITRES:
		var l := UI.label("%s  %s · %s" % ["◆" if c[2] else "◇", c[0], c[1]], 25, Game.SAND if c[2] else Game.MUTED)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(l)
	v.add_child(UI.label("Le chapitre 13 se passe douze ans plus tard, à Médine. Tu peux le voir dès maintenant en aperçu.", 22, Game.MUTED))
	var preview := UI.button("Aperçu du chapitre 13", false)
	preview.autowrap_mode = TextServer.AUTOWRAP_OFF
	preview.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	preview.pressed.connect(func() -> void: Transition.go("res://scenes/medine.tscn", Game.SAND_WARM, "Aperçu · chapitre 13\nMédine, an 1 de l'Hégire"))
	v.add_child(preview)
	var voy := UI.button("Ton voyage", false)
	voy.pressed.connect(func() -> void: Transition.go("res://scenes/voyage.tscn", Game.NIGHT_DEEP))
	v.add_child(voy)
	var menu := UI.button("Revenir au menu")
	menu.pressed.connect(func() -> void: Transition.go("res://scenes/menu.tscn", Game.NIGHT_DEEP))
	v.add_child(menu)
	UI.fade_in(panel, 0.8)


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	var vs := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vs), Game.NIGHT_DEEP)
	Art.star_pattern(self, Rect2(Vector2.ZERO, vs), 64.0, Color(0.79, 0.64, 0.29, 0.08))
	Art.lantern(self, Vector2(vs.x * 0.5, 60.0), 1.0, 1.0, sin(time * 4.0) * 0.08)
