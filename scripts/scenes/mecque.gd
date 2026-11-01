extends Node2D
## Épisode 1 : Selim, dix ans, dans les ruelles de la Mecque (an 610).
## Une ruelle à explorer, plus large que l'écran : la caméra suit Selim.
## - Décor en couches (parallaxe) : montagnes et Jabal an-Nour, la Kaaba au loin, la ruelle.
## - Vie : passants qui saluent, marchand, chat, chameau, linge au vent, oiseaux, poussière.
## - Petites lumières à toucher : on découvre la ville (et des mots arabes).
## - La colombe guide Selim jusqu'à la porte de la voisine, Oumm Nour.
## Le Prophète ﷺ n'apparaît pas : on entend seulement ce que les gens murmurent.

const WORLD_W := 1872.0
const STALL_X := 560.0
const WELL_X := 1165.0
const CAMEL_X := 1460.0
const DOOR_X := 1730.0
const SQUARE := Vector2(1000.0, 1330.0)
const FAR_F := 0.15
const MID_F := 0.5
const JABAL_X := 600.0
const KAABA_X := 765.0

var time := 0.0
var selim_x := 160.0
var cam_x := 0.0
var walking := false
var dove_pos := Vector2.ZERO
var dove_flying := false
var neighbor_a := 0.0

var _g := 0.0
var _talked := false
var _busy := false
var _box: DialogueBox
var _hint: Label
var _words_lbl: Label
var _walk_tw: Tween
var _step_t := 0.0
var _visited := {}
var _npcs: Array[Dictionary] = []
var _motes: Array[Vector3] = []
var _birds: Array[Vector3] = []


func _ready() -> void:
	Audio.set_ambience("town", 0.3)
	var vs := get_viewport_rect().size
	_g = vs.y * 0.6
	dove_pos = Vector2(selim_x + 240.0, vs.y * 0.3)

	# Passants (personnages fictifs) : position, vitesse, taille, couleurs, objet porté.
	_npcs = [
		{"x": 900.0, "v": -42.0, "h": 165.0, "robe": Color("7a4a3a"), "wrap": Color("e9e1cf"), "veil": false, "carry": "jarre", "said": -99.0},
		{"x": 300.0, "v": 34.0, "h": 158.0, "robe": Color("4a3a5c"), "wrap": Color("2b2035"), "veil": true, "carry": "panier", "said": -99.0},
		{"x": 1500.0, "v": -95.0, "h": 110.0, "robe": Color("b5653f"), "wrap": Color("e9e1cf"), "veil": false, "carry": "", "said": -99.0},
		{"x": 1250.0, "v": 22.0, "h": 170.0, "robe": Color("5c5446"), "wrap": Color("f3efe4"), "veil": false, "carry": "baton", "said": -99.0},
	]
	for i in 45:
		_motes.append(Vector3(randf() * vs.x, randf() * vs.y * 0.9, randf() * TAU))
	for i in 3:
		_birds.append(Vector3(randf() * vs.x, vs.y * randf_range(0.05, 0.16), randf_range(60.0, 110.0)))

	var root := UI.layer(self)
	var place := UI.label("La Mecque · an 610 · Selim, 10 ans", 24, Game.INK)
	place.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	UI.dock_top(place, 32, 44)
	place.offset_right = -130
	root.add_child(place)
	_words_lbl = UI.label("", 22, Color("6e4a10"))
	_words_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	UI.dock_top(_words_lbl, 32, 82)
	root.add_child(_words_lbl)
	_refresh_words()
	Game.word_added.connect(func(_k: String) -> void: _refresh_words())

	_hint = UI.label("Touche le sol pour faire marcher Selim.\nTouche les petites lumières pour découvrir la ville.", 28, Game.INK, Game.font_title)
	UI.dock_bottom(_hint, 40, 110)
	root.add_child(_hint)
	_hint.modulate.a = 0.0

	_box = DialogueBox.new()
	UI.dock_bottom(_box, 28, 40)
	_box.visible = false
	root.add_child(_box)
	PauseMenu.attach(self, 610, "La Mecque · an 610 · Selim a 10 ans")
	_intro(root)


func _intro(root: Control) -> void:
	_busy = true
	_hint.modulate.a = 0.0
	await UI.place_banner(root, "La Mecque", "an 610 · Selim a 10 ans", false)
	_busy = false
	UI.fade_in(_hint, 0.8)


func _refresh_words() -> void:
	var n := Game.words.size()
	_words_lbl.text = "Carnet : %d mot%s" % [n, "s" if n > 1 else ""]


# --- Contrôles ---

func _unhandled_input(event: InputEvent) -> void:
	if _talked or _busy or Transition.busy:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p := get_global_mouse_position()
		var spot := _hotspot_at(p)
		if spot != "":
			_explain(spot)
			return
		if p.y > _g - 160.0:
			_walk_to(clampf(p.x + cam_x, 80.0, WORLD_W - 80.0))


func _walk_to(x: float) -> void:
	if _walk_tw:
		_walk_tw.kill()
	walking = true
	if _hint.modulate.a > 0.0:
		create_tween().tween_property(_hint, "modulate:a", 0.0, 0.6).set_delay(2.5)
	_walk_tw = create_tween()
	_walk_tw.tween_property(self, "selim_x", x, maxf(absf(x - selim_x) / 260.0, 0.2))
	_walk_tw.tween_callback(_arrived)


func _arrived() -> void:
	walking = false
	if not _talked and absf(selim_x - DOOR_X) < 100.0:
		_talked = true
		_conversation()


# --- Points à découvrir ---

func _hotspots() -> Dictionary:
	var vs := get_viewport_rect().size
	return {
		"jabal": Vector2(JABAL_X - cam_x * FAR_F, vs.y * 0.075),
		"kaaba": Vector2(KAABA_X - cam_x * MID_F, vs.y * 0.395),
		"marche": Vector2(STALL_X + 110.0 - cam_x, _g - 170.0),
		"puits": Vector2(WELL_X - cam_x, _g - 80.0),
		"chameau": Vector2(CAMEL_X - cam_x, _g - 20.0),
	}


func _hotspot_at(p: Vector2) -> String:
	var spots := _hotspots()
	for key in spots:
		if p.distance_to(spots[key]) < 80.0:
			return key
	return ""


func _explain(key: String) -> void:
	_busy = true
	if _walk_tw:
		_walk_tw.kill()
	walking = false
	var first := not _visited.has(key)
	_visited[key] = true
	Audio.sfx("decouverte", -6.0)
	Input.vibrate_handheld(20)
	match key:
		"jabal":
			await _box.say("Jabal an-Nour", "Au loin, la montagne de la Lumière : Jabal an-Nour. Tout en haut se cache une petite grotte, la grotte de Hira.", ["nour"])
		"kaaba":
			await _box.say("La Kaaba", "La Kaaba : la maison bâtie par Ibrâhîm et son fils Ismâʿîl, paix sur eux, pour adorer Dieu, l'Unique. Mais en ce temps-là, les gens de la Mecque y avaient placé des idoles.", ["kaaba"])
		"marche":
			await _box.say("Le marché", "Des dattes, du lait, des étoffes… La Mecque est une ville de marchands : ses caravanes partent vers le Yémen en hiver, et vers le Shâm en été.", ["tamr"])
		"puits":
			await _box.say("Le puits", "Ici, aucune rivière : l'eau est précieuse. Près de la Kaaba coule la source de Zamzam, jaillie autrefois pour Hâjar et son fils Ismâʿîl.", ["zamzam"])
		"chameau":
			await _box.say("Le chameau", "Le chameau, compagnon des caravanes. Il peut marcher des jours dans le désert sans boire.", ["jamal"])
	_box.visible = false
	if first and _visited.size() == _hotspots().size():
		await _box.say("Le conteur", "[i]Ce matin-là, j'avais l'impression de voir ma ville pour la première fois.[/i]")
		_box.visible = false
	_busy = false


# --- La rencontre avec la voisine ---

func _conversation() -> void:
	create_tween().tween_property(_hint, "modulate:a", 0.0, 0.3)
	create_tween().tween_property(self, "neighbor_a", 1.0, 0.6)
	await get_tree().create_timer(0.5).timeout
	await _box.say("Oumm Nour, la voisine", "As-salâmu ʿalaykum, yâ Selîm ! Tu es bien matinal aujourd'hui.", ["salam"])
	_box.show_text("", "[i]Comment Selim répond-il ?[/i]")
	var choice := await _box.ask(["Répondre « Wa ʿalaykumu s-salâm »", "Lui faire un signe de la main"])
	if choice == 1:
		await _box.say("Oumm Nour, la voisine", "Ici, on se salue avec des mots de paix, mon garçon. Réponds-moi : Wa ʿalaykumu s-salâm !", ["wa_salam"])
	else:
		Game.add_word("wa_salam")
		await _box.say("Selim", "Wa ʿalaykumu s-salâm, Oumm Nour !", ["wa_salam"])
	await _box.say("Oumm Nour, la voisine", "Tiens, prends ces dattes. Et n'oublie pas de dire Bismillâh avant de manger.", ["bismillah"])
	await _box.say("Selim", "Bismillâh… Mmm ! Alhamdulillâh !", ["bismillah", "alhamdulillah"])
	await _box.say("Oumm Nour, la voisine", "[i](Elle baisse la voix.)[/i] As-tu entendu ce que l'on raconte ? Muhammad, fils de ʿAbdallâh ﷺ, celui que toute la Mecque appelle Al-Amîn…", ["amin"])
	await _box.say("Oumm Nour, la voisine", "Il s'isolait pour prier dans la grotte de Hira. On dit que l'ange Jibrîl lui est apparu, et lui a dit : « Iqraʾ ! »", ["iqra"])
	await _box.say("Selim", "Iqraʾ… « Lis ! »  Al-Amîn, l'homme le plus honnête de la Mecque… Je veux comprendre ce qui se passe.")
	await _box.say("Le conteur", "[i]Ce jour-là, mon petit, je ne savais pas encore que toute ma vie allait suivre ce murmure.[/i]")
	_dove_leaves()
	_box.show_text("", "[i]La colombe s'envole au-dessus des toits.[/i]")
	await _box.ask(["Suivre la colombe"])
	Transition.go("res://scenes/medine.tscn", Game.SAND_WARM, "Douze ans plus tard…")


# --- La colombe guide Selim ---

func _dove_update() -> void:
	if dove_flying or _talked:
		return
	var vs := get_viewport_rect().size
	var target := minf(selim_x + 240.0, DOOR_X - 20.0)
	if absf(target - dove_pos.x) > 200.0:
		_dove_fly_to(Vector2(target, vs.y * (0.3 if target < DOOR_X - 40.0 else 0.27)))


func _dove_fly_to(to: Vector2) -> void:
	dove_flying = true
	Audio.sfx("ailes", -14.0)
	var mid := (dove_pos + to) * 0.5 + Vector2(0, -90.0)
	var tw := create_tween()
	tw.tween_property(self, "dove_pos", mid, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "dove_pos", to, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void: dove_flying = false)


func _dove_leaves() -> void:
	dove_flying = true
	Audio.sfx("ailes", -8.0)
	var vs := get_viewport_rect().size
	var tw := create_tween()
	tw.tween_property(self, "dove_pos", Vector2(cam_x + vs.x * 0.7, vs.y * 0.08), 1.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "dove_pos", Vector2(cam_x + vs.x + 80.0, -40.0), 1.4)


# --- Boucle ---

func _process(delta: float) -> void:
	time += delta
	var vs := get_viewport_rect().size
	var target := clampf(selim_x - vs.x * 0.42, 0.0, WORLD_W - vs.x)
	cam_x = lerpf(cam_x, target, clampf(delta * 3.0, 0.0, 1.0))
	if walking:
		_step_t += delta
		if _step_t > 0.32:
			_step_t = 0.0
			Audio.sfx("pas", -12.0, randf_range(0.85, 1.15))
	_dove_update()
	for n in _npcs:
		n["x"] = fmod(float(n["x"]) + float(n["v"]) * delta + WORLD_W + 400.0, WORLD_W + 400.0)
		var x: float = float(n["x"]) - 200.0
		if not _talked and not _busy and absf(x - selim_x) < 110.0 and time - float(n["said"]) > 25.0:
			n["said"] = time
			if not _box.visible:
				Audio.speak("Un passant", "As-salâmu ʿalaykum !")
	for i in _motes.size():
		var m := _motes[i]
		m.x = fmod(m.x + delta * 8.0 + vs.x, vs.x)
		m.y = fmod(m.y - delta * 5.0 + vs.y, vs.y)
		_motes[i] = m
	for i in _birds.size():
		var b := _birds[i]
		b.x += b.z * delta
		if b.x > vs.x + 60.0:
			b.x = -60.0 - randf() * 400.0
			b.y = vs.y * randf_range(0.05, 0.16)
		_birds[i] = b
	queue_redraw()


# --- Dessin ---

func _draw() -> void:
	var vs := get_viewport_rect().size
	var w := vs.x
	var h := vs.y
	var g := _g

	# Ciel : bleu pâle en haut, chaud vers l'horizon.
	var sky := [Color("bfdcea"), Color("d4e2dc"), Color("ead9b4"), Color("f6d9a0")]
	for i in 4:
		draw_rect(Rect2(0, h * 0.09 * i, w, h * 0.09 + 1.0), sky[i])
	draw_rect(Rect2(0, h * 0.36, w, g - h * 0.36), sky[3])
	draw_circle(Vector2(w * 0.84, h * 0.07), 44.0, Color("fff2c9"))
	draw_circle(Vector2(w * 0.84, h * 0.07), 80.0, Color(1.0, 0.95, 0.8, 0.25))

	# Couche lointaine : montagnes et Jabal an-Nour.
	draw_set_transform(Vector2(-cam_x * FAR_F, 0))
	var far_w := WORLD_W * FAR_F + w + 40.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(-20, h * 0.2), Vector2(120, h * 0.13), Vector2(260, h * 0.18), Vector2(380, h * 0.12),
		Vector2(JABAL_X - 70.0, h * 0.14), Vector2(JABAL_X, h * 0.055), Vector2(JABAL_X + 80.0, h * 0.15),
		Vector2(820, h * 0.12), Vector2(960, h * 0.17), Vector2(far_w, h * 0.14), Vector2(far_w, h * 0.3), Vector2(-20, h * 0.3)]), Color("d8bd8f"))
	draw_circle(Vector2(JABAL_X + 8.0, h * 0.072), 4.0, Color("6e5434"))
	draw_set_transform(Vector2.ZERO)

	# Couche du milieu : maisons lointaines et la Kaaba.
	draw_set_transform(Vector2(-cam_x * MID_F, 0))
	var mid_w := WORLD_W * MID_F + w
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var mx := -20.0
	while mx < mid_w:
		var bw := rng.randf_range(60.0, 130.0)
		var top := h * rng.randf_range(0.3, 0.4)
		if absf(mx + bw * 0.5 - KAABA_X) > 110.0:
			draw_rect(Rect2(mx, top, bw - 4.0, h * 0.5 - top), Color("e6c99c"))
			draw_rect(Rect2(mx + bw * 0.4, top + 18.0, 10.0, 14.0), Color("c9a473"))
		mx += bw
	var kb := Vector2(KAABA_X, h * 0.46)
	draw_colored_polygon(PackedVector2Array([kb + Vector2(-46, -96), kb + Vector2(-30, -110), kb + Vector2(62, -110), kb + Vector2(46, -96)]), Color("2e2a26"))
	draw_rect(Rect2(kb + Vector2(-46, -96), Vector2(92, 96)), Color("1c1a18"))
	draw_colored_polygon(PackedVector2Array([kb + Vector2(46, -96), kb + Vector2(62, -110), kb + Vector2(62, -14), kb + Vector2(46, 0)]), Color("141210"))
	draw_set_transform(Vector2.ZERO)

	# Couche de la ruelle.
	draw_set_transform(Vector2(-cam_x, 0))
	_draw_facades(h, g)
	draw_rect(Rect2(-40.0, g, WORLD_W + 80.0, h - g), Color("d7b074"))
	var prng := RandomNumberGenerator.new()
	prng.seed = 3
	for i in 70:
		draw_circle(Vector2(prng.randf() * WORLD_W, g + 16.0 + prng.randf() * (h - g)), prng.randf_range(2.0, 5.0), Color("c49a5c"))
	Art.palm(self, Vector2(380.0, g + 6.0), 300.0, sin(time * 0.9), -0.25)
	Art.palm(self, Vector2(1290.0, g + 6.0), 330.0, sin(time * 0.8 + 1.5), 0.2)
	_draw_stall(g)
	_draw_well(g)
	_draw_camel(g)
	_draw_cat(g)
	# Porte de la voisine.
	_arch(Vector2(DOOR_X, g - 220.0), 130.0, 220.0, Color("5c3a1e"))
	_arch(Vector2(DOOR_X, g - 206.0), 110.0, 206.0, Color("3e2612"))
	draw_colored_polygon(PackedVector2Array([Vector2(DOOR_X + 75.0, g - 30.0), Vector2(DOOR_X + 115.0, g - 30.0), Vector2(DOOR_X + 108.0, g), Vector2(DOOR_X + 82.0, g)]), Color("a8643a"))
	Art.palm(self, Vector2(DOOR_X + 95.0, g - 28.0), 70.0, sin(time * 1.4) * 0.5, 0.0)
	if neighbor_a > 0.0:
		Art.person(self, Vector2(DOOR_X, g - 4.0), 170.0, Art.fade(Color("6b3f4a"), neighbor_a), Color("3e2a1a"), Art.fade(Color("2b3e5c"), neighbor_a), true)
	# Passants.
	for n in _npcs:
		_draw_npc(n, g)
	# La colombe.
	var flap := sin(time * (16.0 if dove_flying else 2.0))
	var hop := 0.0 if dove_flying else absf(sin(time * 1.3)) * -3.0
	Art.dove(self, dove_pos + Vector2(0, hop), 1.3, flap if dove_flying else flap * 0.15)
	# Selim, dix ans, vu de dos.
	var bob := absf(sin(time * 10.0)) * -6.0 if walking else 0.0
	draw_colored_polygon(Art.ellipse(Vector2(selim_x, g + 110.0), 40.0, 10.0), Color(0, 0, 0, 0.12))
	Art.person(self, Vector2(selim_x, g + 110.0 + bob), 190.0, Game.TEAL, Color("3e2612"), Color("e9e1cf"))
	draw_set_transform(Vector2.ZERO)

	# Lumière : rayons, poussière dorée, oiseaux.
	for i in 3:
		var x0 := w * (0.55 + 0.17 * i) + sin(time * 0.3 + i) * 10.0
		draw_colored_polygon(PackedVector2Array([Vector2(x0, 0), Vector2(x0 + 50.0, 0), Vector2(x0 - 160.0, g), Vector2(x0 - 260.0, g)]), Color(1.0, 0.96, 0.82, 0.06))
	for m in _motes:
		draw_circle(Vector2(m.x, m.y + sin(time + m.z) * 6.0), 1.6, Color(1.0, 0.93, 0.7, 0.35 + 0.25 * sin(time * 2.0 + m.z)))
	for b in _birds:
		var wing := 7.0 + 4.0 * sin(time * 12.0 + b.y)
		draw_polyline(PackedVector2Array([Vector2(b.x - wing, b.y - wing * 0.5), Vector2(b.x, b.y), Vector2(b.x + wing, b.y - wing * 0.5)]), Color("5c4a32"), 2.0, true)

	# Bulles de salutation des passants.
	for n in _npcs:
		var age := time - float(n["said"])
		if age < 2.4:
			var sx := float(n["x"]) - 200.0 - cam_x
			_bubble(Vector2(sx, g + 70.0 - float(n["h"]) - 40.0), "As-salâmu ʿalaykum !", clampf(minf(age * 4.0, (2.4 - age) * 3.0), 0.0, 1.0))

	# Petites lumières sur les points à découvrir.
	if not _talked:
		var spots := _hotspots()
		for key in spots:
			var p: Vector2 = spots[key]
			if p.x < -40.0 or p.x > w + 40.0:
				continue
			var seen := _visited.has(key)
			var pulse := 0.6 + 0.4 * sin(time * 3.0 + p.x)
			var a := 0.35 if seen else 1.0
			draw_circle(p, 26.0 * pulse, Color(1.0, 0.95, 0.7, 0.22 * a))
			_sparkle(p, 12.0 + 4.0 * pulse, Color(1.0, 0.97, 0.85, 0.95 * a))
		# Flèche vers la porte quand elle est hors de l'écran.
		if DOOR_X - cam_x > w + 20.0 and not _box.visible:
			var ax := w - 34.0 + sin(time * 4.0) * 6.0
			for k in 2:
				var x := ax - k * 18.0
				draw_polyline(PackedVector2Array([Vector2(x - 10.0, g - 30.0), Vector2(x, g - 18.0), Vector2(x - 10.0, g - 6.0)]), Color("6e4a10", 0.8), 4.0, true)


func _draw_facades(h: float, g: float) -> void:
	var houses := [
		[-40.0, 260.0, 0.15, Color("d9a866")], [220.0, 340.0, 0.2, Color("e8c185")],
		[810.0, 190.0, 0.13, Color("c99355")], [SQUARE.y, 230.0, 0.16, Color("dfb57a")],
		[1560.0, 100.0, 0.22, Color("d4a062")], [1660.0, 260.0, 0.14, Color("e8c185")],
	]
	for hs in houses:
		var x0: float = hs[0]
		var bw: float = hs[1]
		if bw <= 0.0:
			continue
		var top: float = h * float(hs[2])
		draw_rect(Rect2(x0, top, bw, g - top), hs[3])
		draw_rect(Rect2(x0, top - 8.0, bw, 10.0), (hs[3] as Color).darkened(0.12))
		var nwin := int(bw / 110.0)
		for k in nwin:
			var wx := x0 + (k + 0.5) * bw / nwin
			_arch(Vector2(wx, top + 70.0), 32.0, 50.0, Color("7a4e1e"))
	# Maison du marchand (derrière l'étal), plus basse.
	draw_rect(Rect2(560.0, h * 0.24, 250.0, g - h * 0.24), Color("e2bc82"))
	draw_rect(Rect2(560.0, h * 0.24 - 8.0, 250.0, 10.0), Color("c9a06a"))
	# Linge entre deux maisons.
	var a := Vector2(600.0, h * 0.27)
	var b := Vector2(780.0, h * 0.27)
	var pts := PackedVector2Array()
	for i in 11:
		var t := i / 10.0
		pts.append(a.lerp(b, t) + Vector2(0, sin(t * PI) * 22.0))
	draw_polyline(pts, Color("6e5434"), 2.0, true)
	var cloths := [[0.25, Color("2f7f7a")], [0.5, Color("b54a3a")], [0.75, Color("e8c877")]]
	for c in cloths:
		var t: float = c[0]
		var top_p := a.lerp(b, t) + Vector2(0, sin(t * PI) * 22.0)
		var sway := sin(time * 1.8 + t * 6.0) * 8.0
		draw_colored_polygon(PackedVector2Array([top_p + Vector2(-16, 0), top_p + Vector2(16, 0), top_p + Vector2(16 + sway, 56), top_p + Vector2(-16 + sway, 52)]), c[1])
	# Place ouverte : un muret laisse voir la ville et la Kaaba.
	draw_rect(Rect2(SQUARE.x, h * 0.47, SQUARE.y - SQUARE.x, g - h * 0.47), Color("d9b27a"))
	draw_rect(Rect2(SQUARE.x, h * 0.47 - 8.0, SQUARE.y - SQUARE.x, 10.0), Color("c49a5c"))


func _draw_stall(g: float) -> void:
	var x := STALL_X
	# Le marchand, derrière son étal.
	Art.person(self, Vector2(x + 120.0, g - 30.0), 165.0, Color("8a4f3a"), Color("3e2a1a"), Color("f3efe4"))
	draw_rect(Rect2(x, g - 200.0, 8.0, 200.0), Color("6e4a28"))
	draw_rect(Rect2(x + 232.0, g - 200.0, 8.0, 200.0), Color("6e4a28"))
	# Auvent rayé qui ondule.
	var top := g - 212.0
	for i in 8:
		var col := Color("2f7f7a") if i % 2 == 0 else Color("f3e6cc")
		draw_rect(Rect2(x - 16.0 + i * 34.0, top, 34.0, 34.0), col)
	for i in 8:
		var cx := x - 16.0 + i * 34.0 + 17.0
		var sway := sin(time * 2.2 + i * 0.8) * 3.0
		draw_colored_polygon(Art.ellipse(Vector2(cx, top + 34.0 + sway * 0.3), 17.0, 9.0 + sway, 12), Color("2f7f7a") if i % 2 == 0 else Color("f3e6cc"))
	# Table, paniers de dattes, jarres.
	draw_rect(Rect2(x - 6.0, g - 92.0, 252.0, 18.0), Color("8a6230"))
	draw_rect(Rect2(x, g - 74.0, 240.0, 74.0), Color("b5653f"))
	for k in 3:
		var bc := Vector2(x + 40.0 + k * 80.0, g - 100.0)
		draw_colored_polygon(Art.ellipse(bc, 32.0, 14.0), Color("a87a40"))
		for d in 6:
			draw_circle(bc + Vector2(-18.0 + d * 7.0, -6.0 - (d % 2) * 5.0), 6.0, Color("5c2e14"))
	for k in 2:
		var jx := x + 270.0 + k * 34.0
		draw_colored_polygon(PackedVector2Array([Vector2(jx - 10, g - 70), Vector2(jx + 10, g - 70), Vector2(jx + 18, g - 40), Vector2(jx + 12, g), Vector2(jx - 12, g), Vector2(jx - 18, g - 40)]), Color("c4703f"))
	# Fumée d'un petit feu de cuisine.
	for i in 5:
		var t := fmod(time * 0.4 + i * 0.2, 1.0)
		draw_circle(Vector2(x - 40.0 + sin(time + i) * 8.0 + t * 20.0, g - 30.0 - t * 160.0), 8.0 + t * 18.0, Color(0.95, 0.92, 0.88, 0.25 * (1.0 - t)))


func _draw_well(g: float) -> void:
	var x := WELL_X
	draw_rect(Rect2(x - 70.0, g - 50.0, 140.0, 60.0), Color("b59a7a"))
	draw_colored_polygon(Art.ellipse(Vector2(x, g - 50.0), 70.0, 16.0), Color("4a3a2a"))
	draw_colored_polygon(Art.ellipse(Vector2(x, g + 10.0), 70.0, 14.0), Color("a3876a"))
	for k in 5:
		draw_line(Vector2(x - 56.0 + k * 28.0, g - 40.0), Vector2(x - 56.0 + k * 28.0, g + 8.0), Color("9c8062"), 2.0)
	draw_rect(Rect2(x - 62.0, g - 150.0, 8.0, 100.0), Color("6e4a28"))
	draw_rect(Rect2(x + 54.0, g - 150.0, 8.0, 100.0), Color("6e4a28"))
	draw_rect(Rect2(x - 66.0, g - 156.0, 132.0, 10.0), Color("6e4a28"))
	var by := g - 110.0 + sin(time * 1.5) * 6.0
	draw_line(Vector2(x, g - 146.0), Vector2(x, by), Color("8a6a40"), 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(x - 12, by), Vector2(x + 12, by), Vector2(x + 9, by + 20), Vector2(x - 9, by + 20)]), Color("7a5530"))


func _draw_camel(g: float) -> void:
	var c := Vector2(CAMEL_X, g + 30.0)
	var col := Color("b98a52")
	draw_colored_polygon(Art.ellipse(c + Vector2(4, 4), 92.0, 14.0), Color(0, 0, 0, 0.1))
	draw_colored_polygon(Art.ellipse(c + Vector2(0, -38), 80.0, 36.0), col)
	draw_colored_polygon(Art.ellipse(c + Vector2(-6, -74), 38.0, 26.0), col)
	draw_colored_polygon(Art.ellipse(c + Vector2(-50, -6), 26.0, 9.0), col.darkened(0.15))
	draw_colored_polygon(Art.ellipse(c + Vector2(40, -6), 26.0, 9.0), col.darkened(0.15))
	# Cou et tête qui rumine.
	var chew := sin(time * 2.5) * 3.0
	var head := c + Vector2(118.0, -112.0 + chew)
	draw_polyline(PackedVector2Array([c + Vector2(64, -40), c + Vector2(98, -70), head + Vector2(-10, 8)]), col, 22.0, true)
	draw_colored_polygon(Art.ellipse(head, 24.0, 13.0), col)
	draw_circle(head + Vector2(4, -4), 2.5, Game.INK)
	draw_colored_polygon(Art.ellipse(head + Vector2(-12, -14), 5.0, 8.0), col.darkened(0.1))
	# Queue qui chasse les mouches.
	var tail := sin(time * 1.7) * 10.0
	draw_polyline(PackedVector2Array([c + Vector2(-78, -46), c + Vector2(-92, -30 + tail * 0.5), c + Vector2(-96 + tail, -12)]), col.darkened(0.2), 4.0, true)
	# Tapis de selle.
	draw_colored_polygon(Art.ellipse(c + Vector2(-6, -88), 30.0, 9.0), Color("b54a3a"))


func _draw_cat(g: float) -> void:
	var x := 470.0 + 170.0 * sin(time * 0.12)
	var dir := 1.0 if cos(time * 0.12) > 0.0 else -1.0
	var y := g + 40.0
	var col := Color("6b4a2e")
	var step := absf(sin(time * 6.0)) * 2.0
	draw_colored_polygon(Art.ellipse(Vector2(x, y - 14.0 - step), 26.0, 11.0), col)
	var head := Vector2(x + 26.0 * dir, y - 24.0 - step)
	draw_circle(head, 10.0, col)
	draw_colored_polygon(PackedVector2Array([head + Vector2(-8, -6), head + Vector2(-3, -17), head + Vector2(1, -8)]), col)
	draw_colored_polygon(PackedVector2Array([head + Vector2(8, -6), head + Vector2(3, -17), head + Vector2(-1, -8)]), col)
	for k in 4:
		var lx := x - 16.0 + k * 10.0
		draw_line(Vector2(lx, y - 6.0 - step), Vector2(lx + sin(time * 6.0 + k * 1.6) * 3.0, y), col, 4.0)
	var tail_end := Vector2(x - 40.0 * dir, y - 36.0 + sin(time * 2.0) * 6.0)
	draw_polyline(PackedVector2Array([Vector2(x - 24.0 * dir, y - 16.0), Vector2(x - 38.0 * dir, y - 22.0), tail_end]), col, 4.0, true)


func _draw_npc(n: Dictionary, g: float) -> void:
	var x: float = float(n["x"]) - 200.0
	if x < cam_x - 100.0 or x > cam_x + get_viewport_rect().size.x + 100.0:
		return
	var h: float = n["h"]
	var bob := absf(sin(time * (9.0 if h < 130.0 else 6.0) + x * 0.01)) * -4.0
	var feet := Vector2(x, g + 70.0 + bob)
	Art.person(self, feet, h, n["robe"], Color("3e2a1a"), n["wrap"], n["veil"])
	match str(n["carry"]):
		"jarre":
			var top := feet + Vector2(0, -h - 6.0)
			draw_colored_polygon(PackedVector2Array([top + Vector2(-12, 0), top + Vector2(12, 0), top + Vector2(18, -24), top + Vector2(8, -40), top + Vector2(-8, -40), top + Vector2(-18, -24)]), Color("c4703f"))
		"panier":
			var side := feet + Vector2(h * 0.24, -h * 0.42)
			draw_colored_polygon(Art.ellipse(side, 18.0, 13.0), Color("a87a40"))
		"baton":
			draw_line(feet + Vector2(h * 0.26, 0), feet + Vector2(h * 0.3, -h * 0.85), Color("6e4a28"), 4.0)


func _bubble(tip: Vector2, text: String, a: float) -> void:
	var font := Game.font_body
	var size := 22
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var r := Rect2(tip.x - tw * 0.5 - 16.0, tip.y - 52.0, tw + 32.0, 44.0)
	draw_rect(r, Color(1, 1, 1, 0.92 * a))
	draw_colored_polygon(PackedVector2Array([tip + Vector2(-8, -9), tip + Vector2(8, -9), tip]), Color(1, 1, 1, 0.92 * a))
	draw_string(font, Vector2(r.position.x + 16.0, r.position.y + 30.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(Game.INK, a))


func _sparkle(c: Vector2, r: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.22, -r * 0.22), c + Vector2(r, 0), c + Vector2(r * 0.22, r * 0.22),
		c + Vector2(0, r), c + Vector2(-r * 0.22, r * 0.22), c + Vector2(-r, 0), c + Vector2(-r * 0.22, -r * 0.22)]), col)


func _arch(top_center: Vector2, width: float, height: float, color: Color) -> void:
	var r := width * 0.5
	var pts := PackedVector2Array()
	pts.append(top_center + Vector2(-r, height))
	for i in 17:
		var a := PI + PI * i / 16.0
		pts.append(top_center + Vector2(cos(a) * r, r + sin(a) * r))
	pts.append(top_center + Vector2(r, height))
	draw_colored_polygon(pts, color)
