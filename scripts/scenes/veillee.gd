extends Node2D
## La veillée : un vieil homme raconte à un enfant, près du feu, sous les lanternes.
## (Le joueur découvrira au dernier épisode que le conteur est Selim devenu vieux.)

var time := 0.0
var _box: DialogueBox
var _sparks: CPUParticles2D


func _ready() -> void:
	Audio.set_ambience("fire", 0.45)
	var vs := get_viewport_rect().size
	_sparks = CPUParticles2D.new()
	_sparks.position = Vector2(vs.x * 0.5, vs.y * 0.6)
	_sparks.amount = 28
	_sparks.lifetime = 1.6
	_sparks.direction = Vector2(0, -1)
	_sparks.spread = 18.0
	_sparks.gravity = Vector2(0, -40)
	_sparks.initial_velocity_min = 50.0
	_sparks.initial_velocity_max = 120.0
	_sparks.scale_amount_min = 2.0
	_sparks.scale_amount_max = 4.0
	_sparks.color = Game.FLAME
	var ramp := Gradient.new()
	ramp.set_color(0, Game.FLAME_CORE)
	ramp.set_color(1, Color(Game.FLAME, 0.0))
	_sparks.color_ramp = ramp
	add_child(_sparks)

	var root := UI.layer(self)
	var top := UI.label("Épisode 1 · Le murmure", 24, Game.MUTED)
	UI.dock_top(top, 40, 56)
	root.add_child(top)

	_box = DialogueBox.new()
	UI.dock_bottom(_box, 28, 40)
	_box.visible = false
	root.add_child(_box)
	_story()


func _story() -> void:
	await get_tree().create_timer(1.6).timeout
	await _box.say("Le conteur", "Approche, mon petit. Assieds-toi près du feu… la nuit est douce.")
	await _box.say("Le conteur", "Je vais te raconter ce que mes yeux ont vu, quand j'avais à peine ton âge.")
	await _box.say("L'enfant", "Tu as vraiment tout vu, Jaddî ?", ["jaddi"])
	await _box.say("Le conteur", "Pas tout. Mais beaucoup. Écoute bien… Tout commence à la Mecque, dans les ruelles de mon enfance.")
	_box.show_text("", "[i]Le feu crépite. Les lanternes se balancent doucement.[/i]")
	await _box.ask(["Entrer dans le souvenir"])
	Transition.go("res://scenes/mecque.tscn", Game.SAND_WARM, "La Mecque\nan 610")


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	var vs := get_viewport_rect().size
	var w := vs.x
	var h := vs.y
	draw_rect(Rect2(Vector2.ZERO, vs), Game.NIGHT_DEEP)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 70:
		var p := Vector2(rng.randf() * w, rng.randf() * h * 0.3)
		var a := 0.4 + 0.5 * sin(time * 1.5 + i)
		draw_circle(p, rng.randf_range(0.8, 2.2), Color(Game.SAND, a * 0.8))
	Art.crescent(self, Vector2(w * 0.8, h * 0.09), 34.0, Game.GOLD_LIGHT, Game.NIGHT_DEEP)

	# Guirlande de lanternes.
	var y0 := h * 0.2
	var pts := PackedVector2Array()
	for i in 21:
		var t := i / 20.0
		pts.append(Vector2(t * w, y0 + sin(t * PI) * 60.0))
	draw_polyline(pts, Color("5a6b82"), 2.0, true)
	for i in 5:
		var t := (i + 0.5) / 5.0
		var hook := Vector2(t * w, y0 + sin(t * PI) * 60.0)
		var sway := sin(time * 1.2 + i) * 0.04
		draw_set_transform(hook, sway, Vector2.ONE)
		Art.small_lantern(self, Vector2.ZERO, 1.3, 1.0, sin(time * 9.0 + i * 2.0))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Murs de la cour et sol.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, h * 0.34), Vector2(w * 0.3, h * 0.34), Vector2(w * 0.3, h * 0.31),
		Vector2(w * 0.42, h * 0.31), Vector2(w * 0.42, h * 0.34), Vector2(w, h * 0.34),
		Vector2(w, h), Vector2(0, h)]), Color("14233a"))
	draw_rect(Rect2(w * 0.06, h * 0.4, 60, 90), Color("0e1a2b"))
	draw_rect(Rect2(w * 0.82, h * 0.42, 60, 80), Color("0e1a2b"))
	draw_rect(Rect2(0, h * 0.6, w, h * 0.4), Color("1a2c46"))

	# Feu.
	var fire := Vector2(w * 0.5, h * 0.6)
	var f := sin(time * 8.0) * 0.5 + sin(time * 13.0) * 0.5
	draw_circle(fire + Vector2(0, -30), 190.0 + f * 8.0, Color(Game.FLAME, 0.06))
	draw_circle(fire + Vector2(0, -30), 110.0 + f * 6.0, Color(Game.FLAME, 0.1))
	draw_colored_polygon(PackedVector2Array([fire + Vector2(-46, 0), fire + Vector2(-6 + f * 6.0, -110 - f * 14.0), fire + Vector2(46, 0)]), Color("e8762e"))
	draw_colored_polygon(PackedVector2Array([fire + Vector2(-28, 0), fire + Vector2(4 - f * 5.0, -72 + f * 10.0), fire + Vector2(28, 0)]), Game.FLAME)
	draw_colored_polygon(PackedVector2Array([fire + Vector2(-12, 0), fire + Vector2(0, -36 - f * 6.0), fire + Vector2(12, 0)]), Game.FLAME_CORE)
	draw_rect(Rect2(fire + Vector2(-60, -6), Vector2(120, 14)), Color("5c3a1e"))

	# Le conteur (vieil homme) et l'enfant, éclairés par le feu.
	var robe := Color("2b3e5c")
	Art.seated(self, Vector2(w * 0.22, h * 0.61), 240.0, robe, Color("3e2a1a"), Color("e9e1cf"), true)
	Art.seated(self, Vector2(w * 0.8, h * 0.61), 160.0, Color("24507a"), Color("3e2a1a"), Color("c9a24a"))
