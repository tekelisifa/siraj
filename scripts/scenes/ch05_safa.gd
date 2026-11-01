extends Chapitre
## Chapitre 5 · L'appel sur as-Safâ (vers 610-613). Selim a environ 10 à 13 ans.
## Sources : Coran 26:214 et 111 ; al-Boukhârî 4770 (l'appel sur as-Safâ, la réponse des clans,
## le rejet d'Abû Lahab). « Selon la Sîra » : les trois ans discrets, la maison d'al-Arqam.
## Ce que fait Selim est une fiction. Le Prophète ﷺ n'est pas montré : une lumière au sommet.
## Aucune parole citée mot pour mot : le conteur rapporte au style indirect.

var selim_t := 0.0
var crowd_a := 0.0
var top_light := 0.0


func chapter_info() -> Dictionary:
	return {"num": 5, "year": 612, "where": "La Mecque · vers 610-613 · Selim a environ 10 à 13 ans", "here": "Tu es ici · vers 610-613 · l'appel sur as-Safâ"}


func _ready() -> void:
	Audio.set_ambience("town", 0.25)
	vignette = "ruelles"
	super()


func _story() -> void:
	await banner("La Mecque", "vers 610-613 · Selim a environ 10 à 13 ans")
	await box.say_ref("Le conteur", "Après Hira, le message ne fut pas crié dans les rues. Pendant environ trois ans, il passa discrètement, de personne à personne.", "sira:discret")
	await box.say_ref("Le conteur", "On raconte que les croyants se retrouvaient dans la maison d'al-Arqam, près de la colline d'as-Safâ.", "sira:arqam", ["safa"])
	await box.say_ref("Selim", "Oumm Nour m'avait confié un petit paquet à porter de ce côté-là. Je ne savais pas encore ce qui s'y disait.", "fiction")
	box.visible = false
	await drag_progress("Fais glisser ton doigt pour faire traverser les ruelles à Selim", func(p: float) -> void: selim_t = p, 1300.0)

	# Le verset.
	show_vignette("safa")
	crowd_a = 0.0
	await verse("Sourate ash-Shuʿarâ', « les Poètes » (26:214)", "coran:26:214", [
		"Et avertis tes proches parents.",
	])

	# L'appel public.
	await box.say_ref("Le conteur", "Un matin, le Prophète ﷺ monta sur la colline d'as-Safâ et appela, un à un, les clans de Quraysh.", "bukhari:4770")
	create_tween().tween_property(self, "crowd_a", 1.0, 2.5)
	create_tween().tween_property(self, "top_light", 1.0, 2.0)
	await box.say("Selim", "Les gens accouraient de partout. Je me suis glissé entre les grandes personnes pour voir.")
	await box.say_ref("Le conteur", "Il leur demanda s'ils le croiraient s'il leur annonçait des cavaliers prêts à les attaquer, derrière la vallée.", "bukhari:4770")
	await box.say_ref("Le conteur", "Ils répondirent qu'ils ne l'avaient jamais entendu mentir. Alors il les avertit d'un châtiment à venir s'ils n'adoraient pas Dieu seul.", "bukhari:4770", ["nadhir"])
	await box.say_ref("Le conteur", "Son propre oncle, Abû Lahab, le rejeta durement devant tous. Une sourate fut révélée à son sujet : al-Masad.", "coran:111")

	box.show_text("", "[i]Que fait Selim ?[/i]")
	var c := await box.ask(["Rester écouter jusqu'au bout", "Courir raconter à Oumm Nour"])
	if c == 0:
		await box.say_ref("Selim", "Je suis resté. Les gens se disputaient. Moi, je pensais : « Il n'a jamais menti. Alors pourquoi mentirait-il aujourd'hui ? »", "fiction")
	else:
		await box.say_ref("Oumm Nour, la voisine", "Il ne ment jamais, mon garçon. Toute la Mecque le sait. Garde bien cela dans ton cœur.", "fiction")
	await box.say("Le conteur", "Ce jour-là, le message n'était plus un secret. Les épreuves allaient commencer.")

	await recap([
		"Après environ trois ans de discrétion, l'appel devint public (Sîra).",
		"Sur as-Safâ, même ceux qui le rejetaient reconnaissaient qu'il n'avait jamais menti (al-Boukhârî 4770).",
		"Abû Lahab, son oncle, le rejeta (Coran 111).",
	], ["safa", "nadhir"])
	finish()


# --- Vignettes ---

func _draw_vignette(r: Rect2) -> void:
	match vignette:
		"ruelles":
			_draw_alleys(r)
		"safa":
			_draw_safa(r)


func _draw_alleys(r: Rect2) -> void:
	sky(r, Color("bfe0ea"), Color("f3e6cc"))
	# Façades qui défilent pendant que Selim avance.
	var off := selim_t * 420.0
	for i in 9:
		var x := r.position.x - off + i * 150.0
		var h := 150.0 + (i % 3) * 40.0
		var col := Color("e8c185") if i % 2 == 0 else Color("d9a866")
		draw_rect(Rect2(x, r.end.y - 60.0 - h, 140.0, h), col)
		draw_rect(Rect2(x + 50.0, r.end.y - 60.0 - h + 30.0, 30.0, 40.0), Color("8a5a2c"))
		draw_rect(Rect2(x + 46.0, r.end.y - 120.0, 48.0, 60.0), Color("5a3a1c"))
	draw_rect(Rect2(r.position.x, r.end.y - 60.0, r.size.x, 60.0), Color("d9b682"))
	# Une colline au bout de la ruelle.
	var hill := Vector2(r.end.x - 60.0 - selim_t * 120.0 + 120.0, r.end.y - 60.0)
	draw_colored_polygon(Art.ellipse(hill, 140.0, 90.0), Color("b98d5c"))
	# Selim, de dos, avec son paquet (personnage inventé).
	var sx := r.position.x + 90.0 + selim_t * (r.size.x - 260.0)
	var bob := absf(sin(time * 9.0)) * 4.0 if selim_t < 1.0 else 0.0
	Art.person(self, Vector2(sx, r.end.y - 20.0 - bob), 120.0, Color("b5653f"), Color("3e2a1a"), Color("e9e1cf"))
	draw_rect(Rect2(sx + 14.0, r.end.y - 92.0 - bob, 26.0, 20.0), Color("2f7f7a"))


func _draw_safa(r: Rect2) -> void:
	sky(r, Color("f2d9a6"), Color("f8ead0"))
	mountains(r, r.position.y + r.size.y * 0.55, r.size.y * 0.25, Color("a5794c"), 21)
	var ground_y := r.position.y + r.size.y * 0.8
	draw_rect(Rect2(r.position.x, ground_y, r.size.x, r.end.y - ground_y), Color("d9b682"))
	# La colline d'as-Safâ.
	var top := Vector2(r.position.x + r.size.x * 0.42, r.position.y + r.size.y * 0.42)
	draw_colored_polygon(PackedVector2Array([Vector2(top.x - 230, ground_y + 4), top + Vector2(-40, 0), top + Vector2(40, 6), Vector2(top.x + 250, ground_y + 4)]), Color("b98d5c"))
	if top_light > 0.0:
		var g := top_light * (0.85 + 0.15 * sin(time * 2.0))
		draw_circle(top + Vector2(0, -6), 70.0 * g, Color(Game.FLAME, 0.15 * g))
		draw_circle(top + Vector2(0, -6), 30.0 * g, Color(Game.FLAME_CORE, 0.45 * g))
	# Au loin, la Kaaba.
	kaaba(Vector2(r.end.x - 90.0, ground_y + 10.0), 46.0)
	# La foule, de loin et sans visages : des silhouettes qui arrivent.
	if crowd_a > 0.0:
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		for i in 26:
			var p := Vector2(r.position.x + 40.0 + rng.randf() * (r.size.x - 200.0), ground_y + 8.0 + rng.randf() * 40.0)
			var a := clampf(crowd_a * 1.6 - float(i) / 26.0, 0.0, 1.0)
			if a <= 0.0:
				continue
			var cols := [Color("7a4a3a"), Color("4a3a5c"), Color("5c5446"), Color("2f7f7a"), Color("9c6a3a")]
			var robe: Color = cols[i % cols.size()]
			draw_colored_polygon(Art.ellipse(p + Vector2(0, -16), 9.0, 18.0), Art.fade(robe, a))
			draw_circle(p + Vector2(0, -38), 7.0, Art.fade(Color("3e2a1a"), a))
