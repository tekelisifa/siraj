extends Chapitre
## Chapitre 2 · L'enfance (vers 570-583).
## Récit enluminé, Selim n'est pas né. Le Prophète ﷺ enfant n'est jamais montré :
## on voit le désert, les tentes, un troupeau, une lanterne sur une route, des noms.
## Sources : al-Boukhârî 2262 (les prophètes et les moutons) ; le reste « Selon la Sîra »
## (nourrice Halîma des Banû Saʿd, mort d'Âmina, ʿAbd al-Muttalib, Abû Tâlib, caravane vers le Shâm).

const SHEEP := 6

var sheep: Array[Vector2] = []
var herd_target := Vector2.ZERO
var herding := false
var well := Vector2.ZERO
var lantern_fade := 1.0
var tree_shown: Array[bool] = [false, false, false, false, false, false]
var _tree_rects: Array[Rect2] = []

signal herd_done


func chapter_info() -> Dictionary:
	return {"year": 575, "where": "Le désert, puis la Mecque · vers 570-583 · avant la naissance de Selim", "here": "Tu es ici · l'enfance du Prophète ﷺ · vers 570-583"}


func _ready() -> void:
	Audio.set_ambience("wind", 0.35)
	vignette = "desert"
	super()


func _story() -> void:
	await banner("Le désert", "vers 570-575 · selon la Sîra\navant la naissance de Selim")
	await box.say_ref("Le conteur", "À la Mecque, on confiait souvent les nourrissons à des nourrices du désert, où les enfants grandissaient au grand air.", "sira:halima", ["badiya"])
	await box.say_ref("Le conteur", "Le petit Muhammad ﷺ fut confié à une nourrice des Banû Saʿd : Halîma.", "sira:halima")

	show_map(["mecque", "taif"], "mecque", 21.4, 40.2, 4.0)
	carte.zones = [{"nom": "Le pays des Banû Saʿd (zone approximative)", "lat": 21.0, "lon": 40.75, "r": 0.45}]
	await box.say("Le conteur", "Les Banû Saʿd vivaient sous la tente, loin des maisons de la Mecque. Sur la carte, leur pays n'est qu'une zone approximative.")

	# Garder le troupeau.
	show_vignette("desert")
	_setup_herd()
	await box.say_ref("Le conteur", "Au désert, on apprenait tôt à garder les bêtes et à les mener à l'eau.", "reconstitution", ["ghanam"])
	box.visible = false
	hint("Fais glisser ton doigt : le troupeau suit la lumière jusqu'au puits")
	herding = true
	await herd_done
	herding = false
	hint("")
	await box.say_ref("Le conteur", "Bien plus tard, il dira que tous les prophètes avaient gardé des moutons, et que lui aussi avait gardé ceux des gens de la Mecque.", "bukhari:2262")

	# La perte de sa mère.
	show_vignette("route")
	await box.say_ref("Le conteur", "Il était encore petit quand sa mère, Âmina, mourut.", "sira:famille", ["umm"])
	create_tween().tween_property(self, "lantern_fade", 0.15, 3.0)
	await box.say_ref("Le conteur", "Son grand-père, ʿAbd al-Muttalib, le prit avec lui. Puis, à la mort de son grand-père, ce fut son oncle, Abû Tâlib.", "sira:famille")

	# L'arbre des liens.
	show_vignette("arbre")
	box.visible = false
	hint("Touche chaque nom pour découvrir qui il est")
	for i in tree_shown.size():
		tree_shown[i] = false
	while tree_shown.has(false):
		await target_tapped
	hint("")
	await box.say("Le conteur", "Orphelin très jeune, il ne fut jamais seul : les siens veillèrent sur lui.")

	# La caravane vers le Shâm.
	show_map(["mecque", "medine", "sham"], "mecque", 27.6, 38.0, 16.5)
	await box.say_ref("Le conteur", "Encore jeune, il accompagna son oncle Abû Tâlib dans une caravane vers le Shâm, au nord.", "sira:sham", ["jamal"])
	box.visible = false
	carte.routes = [{"pts": [[21.42, 39.83], [24.47, 39.61], [27.6, 38.2], [30.5, 37.0], [33.5, 36.3]], "progress": 0.0, "approx": true}]
	await drag_progress("Fais glisser ton doigt pour suivre la caravane", func(p: float) -> void: carte.routes[0]["progress"] = p, 1600.0)
	await box.say("Le conteur", "Un long voyage, de puits en puits. Le chemin exact des caravanes n'est pas connu : le trait est approximatif.")

	await recap([
		"Orphelin très jeune, il fut entouré par sa nourrice, son grand-père puis son oncle (Sîra).",
		"Il a gardé les moutons des gens de la Mecque, comme les prophètes avant lui (al-Boukhârî 2262).",
		"Le désert, les caravanes, la patience du berger.",
	], ["badiya", "ghanam", "umm"])
	Transition.go("res://scenes/mecque.tscn", Game.SAND_WARM, "Bien des années plus tard…\nla Mecque, vers 610")


# --- Troupeau ---

func _setup_herd() -> void:
	var r := vignette_rect()
	well = Vector2(r.end.x - 110.0, r.position.y + r.size.y * 0.78)
	herd_target = Vector2(r.position.x + 140.0, r.position.y + r.size.y * 0.8)
	sheep.clear()
	for i in SHEEP:
		sheep.append(herd_target + Vector2(randf_range(-70, 40), randf_range(-30, 40)))


func _unhandled_input(event: InputEvent) -> void:
	if herding and (event is InputEventScreenDrag or event is InputEventScreenTouch or (event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT)):
		var r := vignette_rect().grow(-20.0)
		herd_target = Vector2(clampf(event.position.x, r.position.x, r.end.x), clampf(event.position.y, r.position.y + r.size.y * 0.55, r.end.y))
		return
	if vignette == "arbre" and event is InputEventMouseButton and event.pressed:
		for i in _tree_rects.size():
			if _tree_rects[i].grow(12.0).has_point(event.position) and not tree_shown[i]:
				tree_shown[i] = true
				Input.vibrate_handheld(25)
				target_tapped.emit()
		return
	super(event)


func _process(delta: float) -> void:
	super(delta)
	if vignette == "desert" and not sheep.is_empty():
		var arrived := 0
		for i in sheep.size():
			var goal := herd_target + Vector2((i % 3) * 34.0 - 34.0, (i / 3) * 28.0 - 14.0)
			sheep[i] = sheep[i].lerp(goal, minf(1.0, delta * (1.2 + 0.15 * i)))
			if sheep[i].distance_to(well) < 120.0:
				arrived += 1
		if herding and arrived >= SHEEP - 1:
			herding = false
			Input.vibrate_handheld(40)
			herd_done.emit()


# --- Vignettes ---

func _draw_vignette(r: Rect2) -> void:
	match vignette:
		"desert":
			_draw_desert(r)
		"route":
			_draw_road(r)
		"arbre":
			_draw_tree(r)


func _draw_desert(r: Rect2) -> void:
	sky(r, Color("f4d7a1"), Color("f9ecd2"))
	mountains(r, r.position.y + r.size.y * 0.6, r.size.y * 0.25, Color("b98d5c"), 4)
	draw_rect(Rect2(r.position.x, r.position.y + r.size.y * 0.6, r.size.x, r.size.y * 0.4), Color("e2c08c"))
	# Dunes.
	for i in 3:
		var y := r.position.y + r.size.y * (0.66 + 0.1 * i)
		draw_colored_polygon(Art.ellipse(Vector2(r.position.x + r.size.x * (0.2 + 0.35 * i), y + 30.0), r.size.x * 0.32, 30.0), Color("d8b47e"))
	# Tentes noires des nomades.
	for t in [[0.18, 0.62, 1.0], [0.36, 0.6, 0.8], [0.62, 0.61, 0.9]]:
		var b := Vector2(r.position.x + r.size.x * t[0], r.position.y + r.size.y * t[1])
		var s: float = 70.0 * t[2]
		draw_colored_polygon(PackedVector2Array([b + Vector2(-s, 0), b + Vector2(-s * 0.7, -s * 0.5), b + Vector2(s * 0.7, -s * 0.5), b + Vector2(s, 0)]), Color("2b2420"))
		draw_line(b + Vector2(0, -s * 0.5), b + Vector2(0, 0), Color("4a3a2c"), 3.0)
	# Puits.
	if well != Vector2.ZERO:
		draw_colored_polygon(Art.ellipse(well, 34.0, 12.0), Color("8a6a48"))
		draw_colored_polygon(Art.ellipse(well + Vector2(0, -4), 26.0, 8.0), Color("3c5a66"))
		draw_line(well + Vector2(-30, -6), well + Vector2(-30, -56), Color("6a4a2c"), 4.0)
		draw_line(well + Vector2(30, -6), well + Vector2(30, -56), Color("6a4a2c"), 4.0)
		draw_line(well + Vector2(-34, -56), well + Vector2(34, -56), Color("6a4a2c"), 4.0)
	# Moutons.
	for p in sheep:
		draw_colored_polygon(Art.ellipse(p + Vector2(0, 8), 22.0, 4.0), Color(0, 0, 0, 0.12))
		draw_colored_polygon(Art.ellipse(p, 20.0, 13.0), Color("f4efe4"))
		draw_circle(p + Vector2(18, -6), 7.0, Color("3a3028"))
		draw_line(p + Vector2(-10, 10), p + Vector2(-10, 18), Color("3a3028"), 3.0)
		draw_line(p + Vector2(10, 10), p + Vector2(10, 18), Color("3a3028"), 3.0)
	if herding:
		var g := 0.7 + 0.3 * sin(time * 4.0)
		draw_circle(herd_target, 26.0, Color(Game.FLAME, 0.25 * g))
		draw_circle(herd_target, 9.0, Color(Game.FLAME_CORE, g))


func _draw_road(r: Rect2) -> void:
	sky(r, Color("0f1c33"), Color("3a3a58"))
	stars(r, 50)
	mountains(r, r.position.y + r.size.y * 0.68, r.size.y * 0.22, Color("1f2a40"), 6)
	draw_rect(Rect2(r.position.x, r.position.y + r.size.y * 0.68, r.size.x, r.size.y * 0.32), Color("3c3a4c"))
	# Une route qui s'éloigne.
	var a := Vector2(r.position.x + r.size.x * 0.5, r.end.y)
	draw_colored_polygon(PackedVector2Array([a + Vector2(-120, 0), a + Vector2(120, 0), Vector2(a.x + 8, r.position.y + r.size.y * 0.68), Vector2(a.x - 8, r.position.y + r.size.y * 0.68)]), Color("5a5468"))
	var lp := Vector2(a.x + 70.0, r.position.y + r.size.y * 0.5)
	draw_circle(lp + Vector2(0, 40), 70.0 * lantern_fade, Color(Game.FLAME, 0.15 * lantern_fade))
	Art.lantern(self, lp, 0.9, lantern_fade, sin(time * 6.0) * 0.1)


## Arbre des liens : des noms, jamais de visages. Touchés un par un.
func _draw_tree(r: Rect2) -> void:
	draw_rect(r, Color("f6ecd6"))
	Art.star_pattern(self, r, 48.0, Color(0.79, 0.64, 0.29, 0.12))
	var nodes := [
		["ʿAbd al-Muttalib", "le grand-père", Vector2(0.5, 0.13)],
		["ʿAbdallâh", "le père, mort avant sa naissance", Vector2(0.27, 0.42)],
		["Âmina", "la mère", Vector2(0.73, 0.42)],
		["Abû Tâlib", "l'oncle, fils de ʿAbd al-Muttalib", Vector2(0.27, 0.86)],
		["Halîma", "la nourrice, des Banû Saʿd", Vector2(0.73, 0.86)],
		["Muhammad ﷺ", "", Vector2(0.5, 0.66)],
	]
	_tree_rects.clear()
	var ink := Game.INK
	var pos := func(v: Vector2) -> Vector2: return r.position + Vector2(r.size.x * v.x, r.size.y * v.y)
	# Liens.
	var gm: Vector2 = pos.call(nodes[0][2])
	var fa: Vector2 = pos.call(nodes[1][2])
	var mo: Vector2 = pos.call(nodes[2][2])
	var un: Vector2 = pos.call(nodes[3][2])
	var me: Vector2 = pos.call(nodes[5][2])
	draw_line(gm + Vector2(0, 30), fa + Vector2(0, -30), Color(ink, 0.5), 2.0, true)
	draw_line(gm + Vector2(0, 30), Vector2(gm.x - 210, gm.y + 60), Color(ink, 0.3), 2.0, true)
	draw_line(Vector2(gm.x - 210, gm.y + 60), un + Vector2(-60, -30), Color(ink, 0.3), 2.0, true)
	draw_line(fa + Vector2(60, 0), mo + Vector2(-60, 0), Color(ink, 0.5), 2.0, true)
	draw_line(Vector2(me.x, fa.y), me + Vector2(0, -30), Color(ink, 0.5), 2.0, true)
	for i in nodes.size():
		var n: Array = nodes[i]
		var c: Vector2 = pos.call(n[2])
		var rect := Rect2(c - Vector2(130, 30), Vector2(260, 60))
		_tree_rects.append(rect)
		var shown: bool = tree_shown[i] if i < tree_shown.size() else true
		var main := i == 5
		draw_rect(rect, Color(Game.GOLD, 0.25) if main else Color(1, 1, 1, 0.5))
		draw_rect(rect, Game.GOLD, false, 2.0)
		draw_string(Game.font_title, rect.position + Vector2(0, 40), str(n[0]), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 28, ink)
		if shown and str(n[1]) != "":
			draw_string(Game.font_body, rect.position + Vector2(-40, 84), str(n[1]), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x + 80, 18, Color(ink, 0.8))
		elif not shown:
			var g := 0.5 + 0.5 * sin(time * 4.0 + i)
			draw_circle(rect.end - Vector2(14, 14), 6.0, Color(Game.FLAME, g))
	draw_string(Game.font_body, Vector2(r.position.x, r.end.y - 10), "Selon la Sîra", HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 14, 18, Color(ink, 0.6))
