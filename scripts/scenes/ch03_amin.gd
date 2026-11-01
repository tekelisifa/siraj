extends Chapitre
## Chapitre 3 · Al-Amîn (vers 595-605).
## Encore un récit enluminé, puis, à la fin, le tout premier souvenir de Selim (5 ans environ).
## Sources : al-Boukhârî 1582 (il portait des pierres pour la Kaaba, avec al-ʿAbbâs) ;
## le surnom al-Amîn, le commerce et le mariage avec Khadîja, la Pierre noire : « Selon la Sîra ».
## Le Prophète ﷺ n'est jamais montré : une lumière seulement, sur la pierre posée.

var loaded := 0
var wall := 0.25
var lift := 0.0
var stone_glow := 0.0
var _bundles: Array[Rect2] = []

signal bundle_loaded


func chapter_info() -> Dictionary:
	return {"num": 3, "year": 600, "where": "La Mecque · vers 595-605", "here": "Tu es ici · vers 595-605 · al-Amîn"}


func _ready() -> void:
	Audio.set_ambience("town", 0.18)
	vignette = "ville"
	super()


func _story() -> void:
	await banner("La Mecque", "vers 595-605 · selon la Sîra")
	await box.say_ref("Le conteur", "L'enfant devint un jeune homme. À la Mecque, tout le monde lui faisait confiance : on l'appelait al-Amîn, le digne de confiance.", "sira:amin", ["amin"])

	# Le commerce de Khadîja.
	show_vignette("caravane")
	await box.say_ref("Le conteur", "Khadîja, une commerçante respectée, lui confia ses marchandises pour une caravane.", "sira:khadija", ["tijara"])
	box.visible = false
	hint("Touche les ballots pour charger la caravane")
	while loaded < 3:
		await bundle_loaded
	hint("")
	await box.say_ref("Le conteur", "Elle apprécia son honnêteté, et ils se marièrent. Il avait environ vingt-cinq ans, selon les récits.", "sira:khadija")

	# La reconstruction de la Kaaba.
	show_vignette("chantier")
	await box.say_ref("Le conteur", "Des années plus tard, les Quraysh rebâtirent la Kaaba. Il portait lui-même des pierres, avec son oncle al-ʿAbbâs.", "bukhari:1582")
	box.visible = false
	await drag_progress("Fais glisser ton doigt pour monter le mur", func(p: float) -> void: wall = 0.25 + 0.6 * p, 1200.0)

	# La Pierre noire : premier souvenir de Selim.
	show_vignette("pierre")
	await box.say_ref("Le conteur", "C'est mon tout premier souvenir. J'avais environ cinq ans, sur les épaules de mon père, dans la foule.", "fiction")
	await box.say_ref("Le conteur", "Les clans se disputaient l'honneur de remettre la Pierre noire à sa place. On aurait pu en venir aux armes.", "sira:pierre", ["hajar_aswad"])
	await box.say_ref("Le conteur", "Il proposa de poser la pierre sur un manteau, et que les chefs de chaque clan le soulèvent ensemble.", "sira:pierre")
	box.visible = false
	await drag_progress("Fais glisser ton doigt vers le haut : tous soulèvent le manteau", func(p: float) -> void: lift = p, 900.0)
	create_tween().tween_property(self, "stone_glow", 1.0, 1.6)
	await box.say_ref("Le conteur", "Puis il remit lui-même la pierre à sa place. Tous étaient satisfaits, et la paix fut gardée.", "sira:pierre")
	await box.say("Le conteur", "Je ne comprenais pas tout. Mais je me souviens du silence, puis des sourires.")

	await recap([
		"On l'appelait al-Amîn, le digne de confiance, avant même la Révélation (Sîra).",
		"Il épousa Khadîja, qui avait apprécié son honnêteté (Sîra).",
		"Il portait des pierres pour rebâtir la Kaaba (al-Boukhârî 1582), et il évita une querelle entre les clans (Sîra).",
	], ["amin", "tijara", "hajar_aswad"])
	finish()


func _unhandled_input(event: InputEvent) -> void:
	if vignette == "caravane" and loaded < 3 and event is InputEventMouseButton and event.pressed:
		for i in _bundles.size():
			if _bundles[i].grow(20.0).has_point(event.position) and i >= loaded:
				loaded += 1
				Input.vibrate_handheld(25)
				Audio.sfx("pas", -10.0, 0.7)
				bundle_loaded.emit()
				return
	super(event)


# --- Vignettes ---

func _draw_vignette(r: Rect2) -> void:
	match vignette:
		"ville":
			_draw_town(r, 0.0)
		"caravane":
			_draw_caravan(r)
		"chantier":
			_draw_town(r, 1.0)
		"pierre":
			_draw_stone(r)


func _draw_town(r: Rect2, works: float) -> void:
	sky(r, Color("f2d9a6"), Color("f8ead0"))
	mountains(r, r.position.y + r.size.y * 0.6, r.size.y * 0.3, Color("a5794c"), 11)
	draw_rect(Rect2(r.position.x, r.position.y + r.size.y * 0.78, r.size.x, r.size.y * 0.22), Color("d9b682"))
	var kb := Vector2(r.position.x + r.size.x * 0.5, r.position.y + r.size.y * 0.88)
	for i in 8:
		var hx := r.position.x + 40.0 + i * (r.size.x - 80.0) / 7.0
		if absf(hx - kb.x) < 90.0:
			continue
		var hh := 46.0 + (i % 3) * 14.0
		draw_rect(Rect2(hx - 30.0, kb.y - hh, 60.0, hh), Color("e8cfa0"))
		draw_rect(Rect2(hx - 7.0, kb.y - hh + 14.0, 14.0, 18.0), Color("8a5a2c"))
	if works <= 0.0:
		kaaba(kb, 64.0)
		return
	# Chantier : le mur monte, des pierres attendent au sol, des échafaudages en bois.
	var w := 120.0
	var h := 120.0 * wall
	draw_rect(Rect2(kb.x - w * 0.5, kb.y - h, w, h), Color("6f6458"))
	for row in int(h / 16.0):
		var y := kb.y - (row + 1) * 16.0
		draw_line(Vector2(kb.x - w * 0.5, y), Vector2(kb.x + w * 0.5, y), Color("4f463c"), 2.0)
	for sx in [-1.0, 1.0]:
		var px: float = kb.x + sx * (w * 0.5 + 18.0)
		draw_line(Vector2(px, kb.y), Vector2(px, kb.y - 140.0), Color("7a5a36"), 5.0)
		for k in 3:
			draw_line(Vector2(px - 18.0, kb.y - 40.0 - k * 40.0), Vector2(px + 18.0, kb.y - 40.0 - k * 40.0), Color("7a5a36"), 4.0)
	for i in 6:
		var sp := Vector2(r.position.x + 70.0 + i * 34.0, kb.y - 6.0 - (i % 2) * 14.0)
		draw_rect(Rect2(sp - Vector2(15, 10), Vector2(30, 20)), Color("8a7d6c"))


func _draw_caravan(r: Rect2) -> void:
	sky(r, Color("f4d7a1"), Color("f9ecd2"))
	draw_rect(Rect2(r.position.x, r.position.y + r.size.y * 0.62, r.size.x, r.size.y * 0.38), Color("e2c08c"))
	for i in 3:
		var y := r.position.y + r.size.y * (0.66 + 0.1 * i)
		draw_colored_polygon(Art.ellipse(Vector2(r.position.x + r.size.x * (0.25 + 0.3 * i), y + 34.0), r.size.x * 0.34, 30.0), Color("d8b47e"))
	# Trois chameaux, et leurs ballots à charger.
	_bundles.clear()
	for i in 3:
		var base := Vector2(r.position.x + r.size.x * (0.17 + 0.3 * i), r.position.y + r.size.y * 0.84)
		_camel(base, 1.45)
		var on_back := base + Vector2(-9, -133)
		var on_ground := base + Vector2(12, 34)
		var pos := on_back if i < loaded else on_ground
		var b := Rect2(pos - Vector2(28, 20), Vector2(56, 40))
		_bundles.append(Rect2(on_ground - Vector2(28, 20), Vector2(56, 40)))
		draw_rect(b, Color("9c3d2e") if i % 2 == 0 else Color("2f7f7a"))
		draw_rect(b, Color("3a2416"), false, 2.0)
		if i >= loaded:
			var g := 0.5 + 0.5 * sin(time * 4.0 + i)
			draw_circle(b.end - Vector2(6, 6), 6.0, Color(Game.FLAME, g))


func _camel(base: Vector2, s: float) -> void:
	var col := Color("b07a46")
	for dx in [-34.0, -18.0, 18.0, 34.0]:
		draw_line(base + Vector2(dx, -40) * s, base + Vector2(dx * 1.05, 6) * s, col.darkened(0.15), 6.0 * s)
	draw_colored_polygon(Art.ellipse(base + Vector2(0, -56) * s, 48.0 * s, 24.0 * s), col)
	draw_colored_polygon(Art.ellipse(base + Vector2(-4, -78) * s, 22.0 * s, 16.0 * s), col)
	draw_line(base + Vector2(42, -60) * s, base + Vector2(64, -96) * s, col, 12.0 * s)
	draw_colored_polygon(Art.ellipse(base + Vector2(72, -100) * s, 14.0 * s, 9.0 * s), col)


## La Pierre noire sur un manteau, entourée des bannières des clans (sans visages).
func _draw_stone(r: Rect2) -> void:
	sky(r, Color("f2d9a6"), Color("f8ead0"))
	draw_rect(Rect2(r.position.x, r.position.y + r.size.y * 0.7, r.size.x, r.size.y * 0.3), Color("d9b682"))
	var kb := Vector2(r.position.x + r.size.x * 0.72, r.position.y + r.size.y * 0.84)
	kaaba(kb, 110.0)
	var cloth_c := Vector2(r.position.x + r.size.x * 0.36, r.position.y + r.size.y * (0.8 - 0.22 * lift))
	var cw := 190.0
	var cloth := PackedVector2Array([cloth_c + Vector2(-cw * 0.5, -10), cloth_c + Vector2(cw * 0.5, -10), cloth_c + Vector2(cw * 0.45, 22), cloth_c + Vector2(-cw * 0.45, 22)])
	draw_colored_polygon(cloth, Color("e9dcc0"))
	draw_polyline(cloth + PackedVector2Array([cloth[0]]), Color("9c7a4a"), 2.0, true)
	var stone := cloth_c + Vector2(0, -14)
	if stone_glow > 0.0:
		# La pierre est posée à l'angle de la Kaaba : une lumière, sans personne.
		stone = cloth_c.lerp(kb + Vector2(-55, -40), stone_glow)
		draw_circle(stone, 46.0 * stone_glow, Color(Game.FLAME, 0.25 * stone_glow))
	draw_colored_polygon(Art.ellipse(stone, 18.0, 12.0), Color("1a1512"))
	# Bannières des clans autour du manteau (couleurs, pas de visages).
	var cols := [Color("9c3d2e"), Color("2f7f7a"), Color("c9a24a"), Color("4a3a5c"), Color("6a7a3a")]
	for i in cols.size():
		var a := PI * (0.15 + 0.7 * i / float(cols.size() - 1))
		var p := cloth_c + Vector2(cos(a) * -cw * 0.62, 70.0 - sin(a) * 30.0)
		draw_line(p, p + Vector2(0, -110), Color("6a4a2c"), 4.0)
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -110), p + Vector2(46, -96), p + Vector2(0, -80)]), cols[i])
		draw_line(p + Vector2(0, -60), cloth_c + Vector2((i - 2) * 40.0, 0), Color(0.4, 0.3, 0.2, 0.35), 2.0)
	draw_string(Game.font_body, Vector2(r.position.x, r.end.y - 10), "Le nombre de clans n'est pas connu avec certitude", HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 14, 17, Color(Game.INK, 0.6))
