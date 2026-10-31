extends Node2D
## Au premier lancement : on invite le joueur à mettre le son (ou à garder les sous-titres).

var time := 0.0


func _ready() -> void:
	Audio.set_ambience("wind", 0.3)
	var root := UI.layer(self)
	var vs := get_viewport_rect().size

	var box := UI.vbox(24)
	box.anchor_left = 0.0
	box.anchor_right = 1.0
	box.offset_left = 56
	box.offset_right = -56
	box.offset_top = vs.y * 0.42
	root.add_child(box)

	box.add_child(UI.label("Cette histoire se vit avec le son", 50, Game.SAND, Game.font_title))
	box.add_child(UI.label("Mets ton casque ou monte le volume. Tu entendras la voix du conteur, les bruits de la Mecque et de Médine, et l'appel à la prière.", 28, Game.MUTED))

	var buttons := UI.vbox(18)
	UI.dock_bottom(buttons, 48, 64)
	root.add_child(buttons)
	var ok := UI.button("C'est fait, je suis prêt")
	ok.pressed.connect(_continue.bind(true))
	buttons.add_child(ok)
	var subs := UI.button("Continuer avec les sous-titres", false)
	subs.pressed.connect(_continue.bind(false))
	buttons.add_child(subs)

	UI.fade_in(box, 0.8, 0.3)
	UI.fade_in(buttons, 0.8, 0.8)


func _continue(with_sound: bool) -> void:
	Game.sound_ack = true
	Game.subtitles = true if not with_sound else Game.subtitles
	Game.save_game()
	Transition.go("res://scenes/menu.tscn", Game.NIGHT_DEEP)


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	var vs := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vs), Game.NIGHT)
	var c := Vector2(vs.x * 0.5, vs.y * 0.24)
	# Ondes sonores qui s'élargissent.
	for i in 3:
		var p := fmod(time * 0.5 + i / 3.0, 1.0)
		draw_arc(c, 110.0 + p * 120.0, 0.0, TAU, 64, Art.fade(Game.GOLD, 0.55 * (1.0 - p)), 2.0, true)
	draw_circle(c, 100.0, Game.NIGHT_BLUE)
	# Casque.
	draw_arc(c + Vector2(0, 14), 52.0, PI, TAU, 32, Game.GOLD_LIGHT, 10.0, true)
	draw_rect(Rect2(c + Vector2(-66, 4), Vector2(28, 50)), Game.GOLD_LIGHT)
	draw_rect(Rect2(c + Vector2(38, 4), Vector2(28, 50)), Game.GOLD_LIGHT)
