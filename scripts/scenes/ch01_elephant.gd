extends Chapitre
## Chapitre 1 · L'Année de l'Éléphant (vers 570, chronologie traditionnelle).
## Récit enluminé : Selim n'est pas né, le conteur rapporte ce que ses aînés lui ont dit.
## Sources : Coran 105 (sourate al-Fîl) ; le nom d'Abraha, le Yémen, l'éléphant qui refuse
## d'avancer et la naissance viennent de la Sîra (repères « Selon la Sîra »).
## Rien n'est montré de l'armée ni des oiseaux : seulement un éléphant lointain et des ombres.

var route_prog := 0.0
var elephant_kneel := 0.0
var shadows_t := -1.0
var lantern_on := 0.0


func chapter_info() -> Dictionary:
	return {"year": 570, "where": "La Mecque · vers 570 · avant la naissance de Selim", "here": "Tu es ici · vers 570 · l'Année de l'Éléphant"}


func _ready() -> void:
	Audio.set_ambience("wind", 0.3)
	vignette = "vallee"
	super()


func _story() -> void:
	await banner("La Mecque", "vers 570, selon la chronologie traditionnelle\navant la naissance de Selim")
	await box.say("Le conteur", "Ce que je vais te raconter, mon petit, je ne l'ai pas vu. Mes aînés me l'ont raconté, et le Coran en parle.")
	await box.say("Le conteur", "La Mecque était une petite ville au creux des montagnes, autour de la Kaaba.", ["kaaba"])

	# L'armée venue du Yémen, sur la carte.
	show_map(["mecque", "sanaa"], "mecque", 18.6, 42.0, 11.0)
	await box.say_ref("Le conteur", "Un jour, une armée arriva du sud, du Yémen. Avec elle marchait un éléphant.", "sira:abraha", ["fil"])
	await box.say_ref("Le conteur", "Selon les récits, son chef s'appelait Abraha. Il voulait détruire la Kaaba.", "sira:abraha")
	box.visible = false
	carte.routes = [{"pts": [[15.37, 44.19], [17.5, 43.4], [19.4, 42.0], [21.42, 39.83]], "progress": 0.0, "approx": true}]
	await drag_progress("Fais glisser ton doigt pour suivre la route", func(p: float) -> void: carte.routes[0]["progress"] = p)
	await box.say("Le conteur", "Environ huit cents kilomètres séparent Sanaa de la Mecque, à vol d'oiseau. Le chemin exact de l'armée, nous ne le connaissons pas.")

	# L'éléphant s'arrête.
	show_vignette("elephant")
	await box.say_ref("Le conteur", "On raconte qu'arrivé près de la Mecque, l'éléphant refusa d'avancer vers la Kaaba.", "sira:abraha")
	create_tween().tween_property(self, "elephant_kneel", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(1.6).timeout

	# Le verset : paysage seul, des ombres passent sur le sable.
	show_vignette("ombres")
	shadows_t = 0.0
	Audio.set_ambience("wind", 0.12)
	await verse("Sourate al-Fîl, « l'Éléphant » (105)", "coran:105", [
		"N'as-tu pas vu comment ton Seigneur a agi envers les gens de l'Éléphant ?",
		"N'a-t-Il pas rendu leur ruse complètement vaine ?",
		"Il envoya contre eux des oiseaux, par volées,",
		"qui leur lançaient des pierres d'argile,",
		"et Il les rendit semblables à de la paille mâchée.",
	])
	Audio.set_ambience("wind", 0.3)
	await box.say_ref("Le conteur", "La Kaaba fut protégée. Depuis, on appelle cette année « l'Année de l'Éléphant ».", "coran:105")

	# La naissance.
	show_vignette("nuit")
	await box.say_ref("Le conteur", "Cette même année, à la Mecque, naquit un enfant du clan des Banû Hâchim : Muhammad ﷺ.", "sira:naissance")
	await box.say_ref("Le conteur", "Son père, ʿAbdallâh, était mort avant sa naissance.", "sira:naissance")
	box.visible = false
	var r := vignette_rect()
	await wait_tap(Rect2(r.position.x + r.size.x * 0.5 - 60, r.position.y + r.size.y * 0.18, 120, 150), "Touche la lanterne pour l'allumer")
	create_tween().tween_property(self, "lantern_on", 1.0, 1.5)
	await get_tree().create_timer(1.2).timeout
	await box.say("Le conteur", "Personne ne savait encore que cet enfant serait le dernier des prophètes.")

	await recap([
		"L'Année de l'Éléphant : la Kaaba fut protégée (Coran 105).",
		"Le Prophète ﷺ naquit à la Mecque cette année-là, vers 570.",
		"Son père était mort avant sa naissance.",
	], ["fil", "kaaba"])
	Transition.go("res://scenes/ch02_enfance.tscn", PARCHMENT, "Les premières années…")


# --- Vignettes ---

func _draw_vignette(r: Rect2) -> void:
	match vignette:
		"vallee":
			_draw_valley(r, false)
		"elephant":
			_draw_valley(r, false)
			_draw_elephant(Vector2(r.position.x + r.size.x * 0.28, r.end.y - r.size.y * 0.16), r.size.y * 0.32)
		"ombres":
			_draw_valley(r, false)
			_draw_shadows(r)
		"nuit":
			_draw_valley(r, true)


func _draw_valley(r: Rect2, night: bool) -> void:
	if night:
		sky(r, Color("0d1a30"), Color("2a3a5c"))
		stars(r, 60)
	else:
		sky(r, Color("f2d9a6"), Color("f8ead0"))
		draw_circle(Vector2(r.end.x - 90, r.position.y + 80), 34.0, Color("fff3d1"))
	var far := Color("8a6a4a") if not night else Color("1d2a40")
	var near := Color("a5794c") if not night else Color("27344c")
	mountains(r, r.position.y + r.size.y * 0.62, r.size.y * 0.32, far, 3)
	mountains(r, r.position.y + r.size.y * 0.78, r.size.y * 0.22, near, 9)
	var ground := Rect2(r.position.x, r.position.y + r.size.y * 0.8, r.size.x, r.size.y * 0.2)
	draw_rect(ground, Color("d9b682") if not night else Color("3a4258"))
	var kb := Vector2(r.position.x + r.size.x * 0.5, r.position.y + r.size.y * 0.86)
	# Quelques maisons basses autour de la Kaaba.
	for i in 7:
		var hx := kb.x + (i - 3) * 62.0 + (18.0 if i % 2 == 0 else -10.0)
		if absf(hx - kb.x) < 40.0:
			continue
		var hh := 26.0 + (i % 3) * 8.0
		var hc := Color("e8cfa0") if not night else Color("4a4f66")
		draw_rect(Rect2(hx - 22.0, kb.y - hh + 6.0, 44.0, hh), hc)
		if night and i % 2 == 1:
			draw_rect(Rect2(hx - 4.0, kb.y - hh + 16.0, 8.0, 10.0), Color(Game.FLAME, 0.7))
	kaaba(kb + Vector2(0, 6), 40.0)
	if night and lantern_on > 0.0:
		var lp := Vector2(kb.x, r.position.y + r.size.y * 0.24)
		draw_circle(lp + Vector2(0, 40), 120.0 * lantern_on, Color(Game.FLAME, 0.12 * lantern_on))
		draw_circle(lp + Vector2(0, 40), 60.0 * lantern_on, Color(Game.FLAME, 0.2 * lantern_on))
	if night:
		Art.lantern(self, Vector2(kb.x, r.position.y + r.size.y * 0.24), 1.0, 0.35 + 0.65 * lantern_on, sin(time * 5.0) * 0.1 * lantern_on)


func _draw_elephant(feet: Vector2, h: float) -> void:
	var k := elephant_kneel
	var col := Color("7d7468")
	var body_c := feet + Vector2(0, -h * (0.55 - 0.18 * k))
	var leg_h := h * (0.38 - 0.24 * k)
	for dx in [-0.42, -0.18, 0.2, 0.42]:
		draw_rect(Rect2(body_c.x + dx * h - h * 0.07, body_c.y + h * 0.1, h * 0.14, leg_h), col.darkened(0.08))
	draw_colored_polygon(Art.ellipse(body_c, h * 0.58, h * 0.32), col)
	var head := body_c + Vector2(h * 0.55, -h * (0.12 - 0.12 * k))
	draw_colored_polygon(Art.ellipse(head, h * 0.22, h * 0.24), col)
	draw_colored_polygon(Art.ellipse(head + Vector2(-h * 0.08, -h * 0.02), h * 0.14, h * 0.2), col.lightened(0.08))
	# Trompe qui pend vers le sol.
	var trunk := PackedVector2Array()
	for i in 9:
		var t := i / 8.0
		trunk.append(head + Vector2(h * 0.16 + sin(t * 1.6) * h * 0.08, h * 0.1 + t * h * (0.42 - 0.12 * k)))
	draw_polyline(trunk, col, h * 0.07, true)
	draw_circle(head + Vector2(h * 0.08, -h * 0.06), h * 0.025, Color("2a2622"))
	draw_colored_polygon(Art.ellipse(feet + Vector2(0, 4), h * 0.8, h * 0.06), Color(0, 0, 0, 0.12))


func _draw_shadows(r: Rect2) -> void:
	if shadows_t < 0.0:
		return
	# Des ombres glissent sur le sable : on ne dessine pas les oiseaux.
	var ground_y := r.position.y + r.size.y * 0.9
	for i in 14:
		var t := fposmod(time * 0.18 + i * 0.137, 1.0)
		var x := lerpf(r.end.x + 40.0, r.position.x - 40.0, t)
		var y := ground_y - (i % 4) * 9.0 - r.size.y * 0.05
		var s := 12.0 + (i % 3) * 4.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - s, y - s * 0.3), Vector2(x, y), Vector2(x + s, y - s * 0.3), Vector2(x, y - s * 0.1)]), Color(0.2, 0.12, 0.05, 0.22))
