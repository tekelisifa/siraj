extends Node2D
## Médine, an 1 de l'Hégire : le premier adhan.
## - Le conteur raconte la mosquée, la question de l'appel à la prière, puis le rêve de
##   ʿAbdallâh ibn Zayd (Abu Dawud, Ahmad, ad-Dârimî). Les sources ne précisent pas l'heure
##   du premier appel : la scène se passe donc en journée, sans heure précise.
## - La mosquée telle qu'elle était : murs de briques de terre, piliers en troncs de palmier,
##   toit de palmes. Pas de minaret (le premier date des Omeyyades) : Bilal appelait depuis le
##   toit de la maison la plus haute près de la mosquée (Abu Dawud 519).
## - Bilal (radiyAllâhu ʿanhu) n'est jamais montré : seulement une lumière douce sur ce toit.
## - Pendant l'appel, les contrôles se figent et les habitants entrent dans la mosquée.

const ADHAN_FILE := "res://audio/adhan.ogg"
const PHRASES := [
	["اللّٰهُ أَكْبَرُ، اللّٰهُ أَكْبَرُ", "Allâhu akbar, Allâhu akbar", "Dieu est le plus grand"],
	["اللّٰهُ أَكْبَرُ، اللّٰهُ أَكْبَرُ", "Allâhu akbar, Allâhu akbar", "Dieu est le plus grand"],
	["أَشْهَدُ أَنْ لَا إِلٰهَ إِلَّا اللّٰهُ", "Ash-hadu an lâ ilâha illâ-Llâh", "J'atteste qu'il n'y a de divinité que Dieu"],
	["أَشْهَدُ أَنْ لَا إِلٰهَ إِلَّا اللّٰهُ", "Ash-hadu an lâ ilâha illâ-Llâh", "J'atteste qu'il n'y a de divinité que Dieu"],
	["أَشْهَدُ أَنَّ مُحَمَّدًا رَسُولُ اللّٰهِ", "Ash-hadu anna Muhammadan rasûlu-Llâh", "J'atteste que Muhammad est le Messager de Dieu"],
	["أَشْهَدُ أَنَّ مُحَمَّدًا رَسُولُ اللّٰهِ", "Ash-hadu anna Muhammadan rasûlu-Llâh", "J'atteste que Muhammad est le Messager de Dieu"],
	["حَيَّ عَلَى الصَّلَاةِ", "Hayya ʿalâ-s-salâh", "Venez à la prière"],
	["حَيَّ عَلَى الصَّلَاةِ", "Hayya ʿalâ-s-salâh", "Venez à la prière"],
	["حَيَّ عَلَى الْفَلَاحِ", "Hayya ʿalâ-l-falâh", "Venez à la réussite"],
	["حَيَّ عَلَى الْفَلَاحِ", "Hayya ʿalâ-l-falâh", "Venez à la réussite"],
	["اللّٰهُ أَكْبَرُ، اللّٰهُ أَكْبَرُ", "Allâhu akbar, Allâhu akbar", "Dieu est le plus grand"],
	["لَا إِلٰهَ إِلَّا اللّٰهُ", "Lâ ilâha illâ-Llâh", "Il n'y a de divinité que Dieu"],
]
## Début de chaque phrase dans l'enregistrement (secondes), mesuré sur les respirations
## du muezzin (légèrement anticipé). Si le fichier change de durée, les temps sont mis à l'échelle.
const PHRASE_TIMES := [0.8, 10.9, 21.0, 28.2, 36.9, 44.5, 53.9, 58.5, 66.1, 70.1, 81.4, 89.2]
const REF_LENGTH := 96.8
const SECONDS_PER_PHRASE := 4.5

var time := 0.0
var selim_y := 0.0
var adhan_on := false
var adhan_t := 0.0
var call_glow := 0.0
var walkers: Array[Dictionary] = []
var birds: Array[Vector3] = []
var motes: Array[Vector3] = []

var _box: DialogueBox
var _pause: PauseMenu
var _sub: VBoxContainer
var _sub_panel: PanelContainer
var _sub_ar: Label
var _sub_lat: Label
var _sub_fr: Label
var _lock: PanelContainer
var _bar: ProgressBar
var _reminder: Label


func _ready() -> void:
	Audio.set_ambience("town", 0.2)
	var vs := get_viewport_rect().size
	selim_y = vs.y + 280.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	for i in 7:
		birds.append(Vector3(vs.x * rng.randf_range(0.3, 0.95), vs.y * rng.randf_range(0.36, 0.42), rng.randf() * TAU))
	for i in 40:
		motes.append(Vector3(rng.randf() * vs.x, rng.randf() * vs.y * 0.75, rng.randf() * TAU))

	var root := UI.layer(self)
	var place := UI.label("Médine · an 1 de l'Hégire · Selim, environ 22 ans", 24, Game.INK)
	place.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	UI.dock_top(place, 32, 44)
	place.offset_right = -130
	root.add_child(place)

	var sub_panel := PanelContainer.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(1.0, 0.97, 0.9, 0.82)
	psb.set_corner_radius_all(26)
	psb.set_content_margin_all(18)
	sub_panel.add_theme_stylebox_override("panel", psb)
	sub_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.dock_top(sub_panel, 28, 112)
	root.add_child(sub_panel)
	_sub = UI.vbox(6)
	_sub.modulate.a = 0.0
	sub_panel.add_child(_sub)
	sub_panel.modulate.a = 0.0
	_sub_panel = sub_panel
	_sub.add_child(UI.label("L'adhan · paroles transmises par ʿAbdallâh ibn Zayd", 28, Game.INK, Game.font_title))
	_sub_ar = UI.label("", 58, Color("8a5a12"), Game.font_arabic)
	_sub.add_child(_sub_ar)
	_sub_lat = UI.label("", 36, Game.INK, Game.font_title)
	_sub.add_child(_sub_lat)
	_sub_fr = UI.label("", 26, Color("5c4a2a"))
	_sub.add_child(_sub_fr)

	_lock = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Game.NIGHT_BLUE, 0.92)
	sb.set_corner_radius_all(26)
	sb.set_content_margin_all(26)
	_lock.add_theme_stylebox_override("panel", sb)
	_lock.mouse_filter = Control.MOUSE_FILTER_STOP
	UI.dock_bottom(_lock, 28, 48)
	_lock.modulate.a = 0.0
	_lock.visible = false
	root.add_child(_lock)
	var lv := UI.vbox(14)
	_lock.add_child(lv)
	lv.add_child(UI.label("Écoute… Le voyage reprendra après l'appel.", 28, Game.SAND))
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 10)
	_bar.max_value = 1.0
	lv.add_child(_bar)

	_reminder = UI.label("Un moment important arrive.\nMonte le son ou mets ton casque.", 34, Game.INK, Game.font_title)
	_reminder.anchor_right = 1.0
	_reminder.anchor_top = 0.24
	_reminder.anchor_bottom = 0.24
	_reminder.offset_left = 40
	_reminder.offset_right = -40
	_reminder.modulate.a = 0.0
	root.add_child(_reminder)

	_box = DialogueBox.new()
	UI.dock_bottom(_box, 28, 40)
	_box.visible = false
	root.add_child(_box)
	_pause = PauseMenu.attach(self, 622, "Médine · an 1 de l'Hégire (622) · Selim a environ 22 ans")
	_story(root)


func _story(root: Control) -> void:
	await UI.place_banner(root, "Médine", "an 1 de l'Hégire (622) · Selim a environ 22 ans", false)
	await _box.say("Le conteur", "Nous étions arrivés à Médine depuis quelques mois. J'avais environ vingt-deux ans.")
	await _box.say_ref("Le conteur", "Avec ses compagnons, le Prophète ﷺ avait bâti la mosquée : des murs de briques de terre, des troncs de palmiers pour piliers, et des palmes pour toit.", "bukhari:446")
	await _box.say_ref("Le conteur", "Mais comment appeler les gens à la prière ? Certains proposaient une cloche, d'autres une corne…", "bukhari:604")
	await _box.say("Le conteur", "Une nuit, un compagnon, ʿAbdallâh ibn Zayd, vit en rêve un homme qui lui apprit les paroles de l'appel.")
	await _box.say_ref("Le conteur", "Au matin, il les raconta au Prophète ﷺ. Celui-ci dit que c'était un rêve vrai, et qu'il fallait les apprendre à Bilal, dont la voix portait plus loin.", "abudawud:499")
	_box.show_text("", "[i]Ce jour-là, Selim se trouve sur le toit de sa maison, tout près de la mosquée.[/i]")
	await _box.ask(["Regarder vers la mosquée"])
	_box.visible = false
	var vs := get_viewport_rect().size
	var tw := create_tween()
	tw.tween_property(self, "selim_y", vs.y * 0.775, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished
	await _box.say_ref("Le conteur", "Et soudain, une voix s'éleva au-dessus de la ville, depuis un toit près de la mosquée.", "reconstitution")
	_box.visible = false
	await _remind_sound()
	await _adhan()
	await _box.say("Le conteur", "C'était la voix de Bilal, radiyAllâhu ʿanhu. Cette voix… je l'entends encore.", ["adhan"])
	await _box.say_ref("Le conteur", "Il n'y avait pas encore de minaret. Bilal montait souvent appeler à l'aube depuis le toit de la maison la plus haute autour de la mosquée, celle d'une femme des Banû an-Najjâr.", "abudawud:519")
	await _box.say_ref("Le conteur", "On raconte aussi qu'en entendant l'appel, ʿUmar sortit de chez lui : il avait vu la même chose en rêve.", "abudawud:499")
	await _box.say("Le conteur", "Ce jour-là, beaucoup sont venus prier. Et moi, j'ai compris que je ne voulais plus jamais être loin de cet appel.")
	_box.show_text("", "[b]Fin de la démo[/b]\nUne lanterne s'est allumée sur ton chemin.")
	await _box.ask(["Retour au menu"])
	Transition.go("res://scenes/menu.tscn", Game.NIGHT_DEEP)


func _remind_sound() -> void:
	var tw := create_tween()
	tw.tween_property(_reminder, "modulate:a", 1.0, 0.5)
	tw.tween_interval(2.4)
	tw.tween_property(_reminder, "modulate:a", 0.0, 0.5)
	await tw.finished


func _adhan() -> void:
	Input.vibrate_handheld(60)
	_pause.locked = true
	Audio.stop_speech()
	Audio.set_ambience("", 0.0)
	_lock.visible = true
	create_tween().tween_property(_lock, "modulate:a", 1.0, 0.6)
	create_tween().tween_property(_sub, "modulate:a", 1.0, 1.0)
	create_tween().tween_property(_sub_panel, "modulate:a", 1.0, 1.0)
	create_tween().tween_property(self, "call_glow", 1.0, 2.0)

	var length := Audio.play_file(ADHAN_FILE)
	var has_audio := length > 0.0
	var total := length if has_audio else SECONDS_PER_PHRASE * PHRASES.size()
	var times: Array[float] = []
	for i in PHRASES.size():
		times.append(float(PHRASE_TIMES[i]) * length / REF_LENGTH if has_audio else i * SECONDS_PER_PHRASE)
	_spawn_walkers(total)

	adhan_on = true
	adhan_t = 0.0
	var current := -1
	var use_clock := not has_audio
	while true:
		var pos := adhan_t
		if not use_clock:
			pos = Audio.voice.get_playback_position()
			# Si la lecture n'avance pas (sortie audio indisponible), on suit l'horloge.
			if adhan_t > 3.0 and pos < 0.05:
				use_clock = true
				pos = adhan_t
			elif not Audio.voice.playing and adhan_t > 1.0:
				break
		if use_clock and pos >= total:
			break
		var idx := current
		while idx + 1 < times.size() and pos >= times[idx + 1]:
			idx += 1
		if idx != current and idx >= 0:
			current = idx
			_show_phrase(PHRASES[idx])
		_bar.value = clampf(pos / total, 0.0, 1.0)
		await get_tree().process_frame

	adhan_on = false
	create_tween().tween_property(_sub, "modulate:a", 0.0, 1.2)
	create_tween().tween_property(_sub_panel, "modulate:a", 0.0, 1.2)
	create_tween().tween_property(self, "call_glow", 0.25, 2.0)
	var tw := create_tween()
	tw.tween_property(_lock, "modulate:a", 0.0, 0.6)
	await tw.finished
	_lock.visible = false
	_pause.locked = false
	Audio.set_ambience("town", 0.12)


func _show_phrase(p: Array) -> void:
	var tw := create_tween()
	tw.tween_property(_sub_ar, "modulate:a", 0.0, 0.25)
	tw.parallel().tween_property(_sub_lat, "modulate:a", 0.0, 0.25)
	tw.parallel().tween_property(_sub_fr, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func() -> void:
		_sub_ar.text = str(p[0])
		_sub_lat.text = str(p[1])
		_sub_fr.text = str(p[2])
	)
	tw.tween_property(_sub_ar, "modulate:a", 1.0, 0.5)
	tw.parallel().tween_property(_sub_lat, "modulate:a", 1.0, 0.5)
	tw.parallel().tween_property(_sub_fr, "modulate:a", 1.0, 0.5)


# --- Les habitants qui viennent prier ---

func _spawn_walkers(total: float) -> void:
	var vs := get_viewport_rect().size
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var robes := [Color("7a4a3a"), Color("4a3a5c"), Color("5c5446"), Color("8a4f3a"), Color("2f5f7a"), Color("6b3f4a"), Color("8a7a5a")]
	for i in 26:
		var from_left := i % 2 == 0
		var start_x := rng.randf_range(-0.25, -0.05) * vs.x if from_left else rng.randf_range(1.05, 1.3) * vs.x
		walkers.append({
			"x": start_x,
			"y": vs.y * rng.randf_range(0.695, 0.725),
			"speed": rng.randf_range(55.0, 85.0),
			"delay": rng.randf_range(1.5, total * 0.6),
			"h": rng.randf_range(78.0, 96.0) * (0.75 if i % 7 == 3 else 1.0),
			"robe": robes[i % robes.size()],
			"veil": i % 3 == 1,
			"phase": rng.randf() * TAU,
			"in": 0.0,
		})


func _update_walkers(delta: float) -> void:
	var vs := get_viewport_rect().size
	var door := Vector2(vs.x * 0.36, vs.y * 0.675)
	for wk in walkers:
		if adhan_t < float(wk["delay"]) and adhan_on:
			continue
		if float(wk["in"]) >= 1.0:
			continue
		var x: float = wk["x"]
		var dx := door.x - x
		if absf(dx) > 6.0:
			wk["x"] = x + signf(dx) * minf(absf(dx), float(wk["speed"]) * delta)
		else:
			# Arrivé à l'entrée : il entre dans la mosquée.
			wk["in"] = minf(1.0, float(wk["in"]) + delta * 0.9)


# --- Boucle ---

func _process(delta: float) -> void:
	time += delta
	if adhan_on:
		adhan_t += delta
	_update_walkers(delta)
	var vs := get_viewport_rect().size
	for i in motes.size():
		var m := motes[i]
		m.x = fmod(m.x + delta * 7.0 + vs.x, vs.x)
		m.y = fmod(m.y - delta * 4.0 + vs.y * 0.75, vs.y * 0.75)
		motes[i] = m
	queue_redraw()


# --- Dessin ---

func _draw() -> void:
	var vs := get_viewport_rect().size
	var w := vs.x
	var h := vs.y

	# Ciel de journée.
	var sky := [Color("9cc6e0"), Color("b4d3e4"), Color("cfe0e2"), Color("e6e0c8"), Color("f2dcb0")]
	for i in 5:
		draw_rect(Rect2(0, h * 0.09 * i, w, h * 0.09 + 1.0), sky[i])
	draw_circle(Vector2(w * 0.18, h * 0.1), 46.0, Color("fff6d8"))
	draw_circle(Vector2(w * 0.18, h * 0.1), 90.0, Color(1.0, 0.97, 0.85, 0.25))
	# Nuages qui passent.
	for k in 3:
		var cx := fmod(time * (6.0 + k * 3.0) + k * 300.0, w + 400.0) - 200.0
		var cy := h * (0.07 + k * 0.06)
		for j in 4:
			draw_colored_polygon(Art.ellipse(Vector2(cx + j * 38.0, cy + (j % 2) * 8.0), 46.0, 18.0), Color(1, 1, 1, 0.55))

	# Le mont Uhud au loin, puis les palmeraies de Médine.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, h * 0.43), Vector2(w * 0.12, h * 0.39), Vector2(w * 0.3, h * 0.36), Vector2(w * 0.45, h * 0.38),
		Vector2(w * 0.62, h * 0.35), Vector2(w * 0.8, h * 0.39), Vector2(w, h * 0.37), Vector2(w, h * 0.46), Vector2(0, h * 0.46)]), Color("b58a66"))
	draw_rect(Rect2(0, h * 0.45, w, h * 0.3), Color("e2c48f"))
	var grove := Color("6f8a5a")
	for i in 11:
		var px := w * (i / 10.0) + sin(i * 7.3) * 22.0
		Art.palm(self, Vector2(px, h * 0.465), 110.0 + (i % 3) * 22.0, sin(time * 0.7 + i) * 0.6, (i % 3 - 1) * 0.15, grove, grove, true)

	# Petites maisons de Médine.
	for hs in [[0.0, 0.5, 0.12, Color("d9b383")], [0.86, 0.49, 0.14, Color("cfa673")], [0.62, 0.53, 0.06, Color("d4ad7c")]]:
		var hx: float = w * float(hs[0])
		var hy: float = h * float(hs[1])
		var hw: float = w * float(hs[2])
		draw_rect(Rect2(hx, hy, hw, h * 0.68 - hy), hs[3])
		draw_rect(Rect2(hx + hw * 0.4, hy + 30.0, 14.0, 20.0), Color("7a4e1e"))

	_draw_mosque(w, h)
	_draw_tall_house(w, h)

	# Rue devant la mosquée.
	draw_rect(Rect2(0, h * 0.68, w, h * 0.07), Color("d9b98a"))
	for wk in walkers:
		_draw_walker(wk)

	# Oiseaux qui s'envolent quand l'appel commence.
	for b in birds:
		var fly := clampf(adhan_t * 0.2, 0.0, 1.0)
		var bp := Vector2(b.x + fly * 360.0 * cos(b.z), b.y - fly * 420.0) + Vector2(0, sin(time * 10.0 + b.z) * 3.0)
		var wing := 7.0 + 4.0 * sin(time * 13.0 + b.z)
		draw_polyline(PackedVector2Array([bp + Vector2(-wing, -wing * 0.5), bp, bp + Vector2(wing, -wing * 0.5)]), Color("5c4a32"), 2.5, true)

	# Toit de Selim au premier plan, palmier, Selim (jeune homme) vu de dos.
	draw_rect(Rect2(0, h * 0.75, w, h * 0.25), Color("b88a5a"))
	draw_rect(Rect2(0, h * 0.75, w, 14.0), Color("a37548"))
	for i in 9:
		draw_line(Vector2(i * w / 8.0, h * 0.765), Vector2(i * w / 8.0 - 40.0, h), Color("a98050"), 2.0)
	Art.palm(self, Vector2(w * 0.03, h * 0.78), 460.0, sin(time * 0.8), 0.35)
	Art.person(self, Vector2(w * 0.9, selim_y), 230.0, Game.TEAL, Color("3e2612"), Color("e9e1cf"))

	# Lumière dorée dans l'air.
	for m in motes:
		draw_circle(Vector2(m.x, m.y + sin(time + m.z) * 6.0), 1.6, Color(1.0, 0.95, 0.75, 0.3 + 0.2 * sin(time * 2.0 + m.z)))


func _draw_mosque(w: float, h: float) -> void:
	var x0 := w * 0.04
	var x1 := w * 0.6
	var top := h * 0.53
	var ground := h * 0.68
	var mud := Color("c99f6e")
	var mud_dark := Color("b08655")
	# Mur du fond.
	draw_rect(Rect2(x0, top, x1 - x0, ground - top), mud)
	for r in 6:
		for c in 14:
			var bx := x0 + c * (x1 - x0) / 14.0 + (12.0 if r % 2 == 1 else 0.0)
			if bx + 30.0 < x1:
				draw_rect(Rect2(bx, top + 6.0 + r * 14.0, 30.0, 1.5), mud_dark)
	# Partie couverte : piliers en troncs de palmier et toit de palmes.
	var cov_x1 := x0 + (x1 - x0) * 0.62
	draw_rect(Rect2(x0, top + 22.0, cov_x1 - x0, ground - top - 22.0), Color("7a5a3a"))
	for i in 7:
		var px := x0 + 16.0 + i * (cov_x1 - x0 - 32.0) / 6.0
		draw_rect(Rect2(px - 5.0, top + 22.0, 10.0, ground - top - 22.0), Color("8a6a44"))
		for k in 5:
			draw_line(Vector2(px - 5.0, top + 34.0 + k * 16.0), Vector2(px + 5.0, top + 38.0 + k * 16.0), Color("6e5232"), 1.5)
	draw_rect(Rect2(x0 - 8.0, top + 6.0, cov_x1 - x0 + 16.0, 20.0), Color("8a7a3e"))
	for i in 42:
		var fx := x0 - 6.0 + i * (cov_x1 - x0 + 12.0) / 41.0
		var sway := sin(time * 1.4 + i * 0.7) * 2.0
		draw_line(Vector2(fx, top + 8.0), Vector2(fx - 6.0 + sway, top + 34.0 + (i % 3) * 4.0), Color("6f7a36") if i % 2 == 0 else Color("8a8a44"), 3.0, true)
	# Cour.
	draw_rect(Rect2(cov_x1, top + 30.0, x1 - cov_x1, ground - top - 30.0), Color("dcc092"))
	# Mur de façade bas, avec l'entrée.
	var door_x := w * 0.36
	var fy := ground - 40.0
	draw_rect(Rect2(x0 - 6.0, fy, door_x - 34.0 - x0 + 6.0, 40.0), mud)
	draw_rect(Rect2(door_x + 34.0, fy, x1 + 6.0 - door_x - 34.0, 40.0), mud)
	draw_rect(Rect2(x0 - 6.0, fy - 4.0, x1 - x0 + 12.0, 5.0), mud_dark)
	draw_rect(Rect2(door_x - 34.0, fy + 2.0, 68.0, 38.0), Color("6b4f32"))


func _draw_tall_house(w: float, h: float) -> void:
	var x0 := w * 0.64
	var x1 := w * 0.84
	var top := h * 0.41
	var ground := h * 0.68
	draw_rect(Rect2(x0, top, x1 - x0, ground - top), Color("d6ad78"))
	draw_rect(Rect2(x0 - 6.0, top - 14.0, x1 - x0 + 12.0, 16.0), Color("c29660"))
	for r in 3:
		for c in 2:
			draw_rect(Rect2(x0 + 26.0 + c * 70.0, top + 40.0 + r * 80.0, 20.0, 30.0), Color("7a4e1e"))
	draw_rect(Rect2(x0 + 50.0, ground - 70.0, 40.0, 70.0), Color("5c3a1e"))
	# Le toit d'où vient l'appel : seulement une lumière douce et des ondes.
	var src := Vector2((x0 + x1) * 0.5, top - 30.0)
	var pulse := 0.1 * sin(time * 2.0) if adhan_on else 0.0
	draw_circle(src, 90.0, Color(1.0, 0.9, 0.55, (0.18 + pulse) * call_glow))
	draw_circle(src, 40.0, Color(1.0, 0.93, 0.7, (0.45 + pulse) * call_glow))
	if adhan_on:
		for i in 4:
			var p := fmod(time * 0.35 + i / 4.0, 1.0)
			draw_arc(src, 40.0 + p * 320.0, PI * 1.05, PI * 1.95, 48, Color(0.55, 0.4, 0.15, 0.55 * (1.0 - p)), 2.5, true)


func _draw_walker(wk: Dictionary) -> void:
	var a := 1.0 - float(wk["in"])
	if a <= 0.0:
		return
	var x: float = wk["x"]
	var y: float = float(wk["y"]) - float(wk["in"]) * 26.0
	var moving := float(wk["in"]) <= 0.0 and adhan_t >= float(wk["delay"])
	var bob := absf(sin(time * 7.0 + float(wk["phase"]))) * -3.0 if moving else 0.0
	var robe: Color = wk["robe"]
	Art.person(self, Vector2(x, y + bob), float(wk["h"]), Art.fade(robe, a), Art.fade(Color("3e2a1a"), a), Art.fade(Color("e9e1cf") if not wk["veil"] else Color("2b2035"), a), bool(wk["veil"]))
