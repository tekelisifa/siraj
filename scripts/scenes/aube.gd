extends Node2D
## Médine, an 1 de l'Hégire, à l'aube : le premier adhan.
## - Selim, devenu jeune homme, monte sur le toit.
## - Pendant l'appel, les contrôles se figent : on écoute.
## - L'adhan est entendu de loin. Bilal (radiyAllâhu ʿanhu) n'est jamais montré.
## - Enregistrement : déposer un adhan enregistré (avec autorisation) dans res://audio/adhan.ogg.

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
const SECONDS_PER_PHRASE := 4.5

var time := 0.0
var dawn := 0.0
var selim_y := 0.0
var adhan_on := false
var adhan_t := 0.0
var birds: Array[Vector3] = []

var _box: DialogueBox
var _sub: VBoxContainer
var _sub_ar: Label
var _sub_lat: Label
var _sub_fr: Label
var _lock: PanelContainer
var _bar: ProgressBar
var _reminder: Label


func _ready() -> void:
	Audio.set_ambience("wind", 0.2)
	var vs := get_viewport_rect().size
	selim_y = vs.y + 260.0
	for i in 7:
		birds.append(Vector3(vs.x * randf_range(0.1, 0.6), vs.y * randf_range(0.52, 0.58), randf() * TAU))

	var root := UI.layer(self)
	var place := UI.label("Médine · an 1 de l'Hégire, à l'aube", 24, Game.MUTED)
	UI.dock_top(place, 32, 50)
	root.add_child(place)

	_sub = UI.vbox(6)
	UI.dock_top(_sub, 36, 150)
	_sub.modulate.a = 0.0
	root.add_child(_sub)
	_sub.add_child(UI.label("L'adhan, tel que Bilal l'a appelé pour la première fois", 30, Game.SAND, Game.font_title))
	_sub_ar = UI.label("", 58, Game.GOLD_LIGHT, Game.font_arabic)
	_sub.add_child(_sub_ar)
	_sub_lat = UI.label("", 36, Game.SAND, Game.font_title)
	_sub.add_child(_sub_lat)
	_sub_fr = UI.label("", 26, Game.MUTED)
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
	var ll := UI.label("Écoute… Le voyage reprendra après l'appel.", 28, Game.SAND)
	lv.add_child(ll)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 10)
	_bar.max_value = 1.0
	lv.add_child(_bar)

	_reminder = UI.label("Un moment important arrive.\nMonte le son ou mets ton casque.", 34, Game.GOLD_LIGHT, Game.font_title)
	_reminder.anchor_right = 1.0
	_reminder.anchor_top = 0.42
	_reminder.anchor_bottom = 0.42
	_reminder.offset_left = 40
	_reminder.offset_right = -40
	_reminder.modulate.a = 0.0
	root.add_child(_reminder)

	_box = DialogueBox.new()
	UI.dock_bottom(_box, 28, 40)
	_box.visible = false
	root.add_child(_box)
	_story()


func _story() -> void:
	await get_tree().create_timer(1.2).timeout
	await _box.say("Le conteur", "Nous étions arrivés à Médine depuis quelques mois. J'avais vingt-deux ans.")
	await _box.say("Le conteur", "Les musulmans construisaient leur mosquée, et cherchaient comment s'appeler les uns les autres à la prière.")
	await _box.say("Le conteur", "Cette nuit-là, je ne dormais pas…")
	_box.show_text("", "[i]Le ciel commence à pâlir au-dessus des palmiers.[/i]")
	await _box.ask(["Monter sur le toit"])
	_box.visible = false
	var vs := get_viewport_rect().size
	var tw := create_tween()
	tw.tween_property(self, "selim_y", vs.y * 0.74, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished
	await _box.say("Le conteur", "Et soudain, une voix s'est élevée au-dessus de la ville.")
	_box.visible = false
	await _remind_sound()
	await _adhan()
	await _box.say("Le conteur", "C'était Bilal, radiyAllâhu ʿanhu. Cette voix… je l'entends encore.", ["adhan"])
	await _box.say("Le conteur", "Ce matin-là, toute Médine s'est levée pour prier. Et moi, j'ai compris que je ne voulais plus jamais être loin de cet appel.")
	_box.show_text("", "[b]Fin de la démo[/b]\nUne lanterne s'est allumée sur ton chemin.")
	await _box.ask(["Retour au menu"])
	Transition.go("res://scenes/menu.tscn", Game.NIGHT_DEEP)


func _remind_sound() -> void:
	# Android ne donne pas le volume système sans plugin : on rappelle toujours, brièvement.
	var tw := create_tween()
	tw.tween_property(_reminder, "modulate:a", 1.0, 0.5)
	tw.tween_interval(2.4)
	tw.tween_property(_reminder, "modulate:a", 0.0, 0.5)
	await tw.finished


func _adhan() -> void:
	Input.vibrate_handheld(60)
	Audio.set_ambience("", 0.0)
	_lock.visible = true
	create_tween().tween_property(_lock, "modulate:a", 1.0, 0.6)
	create_tween().tween_property(_sub, "modulate:a", 1.0, 1.0)
	var length := Audio.play_file(ADHAN_FILE)
	var per := SECONDS_PER_PHRASE if length <= 0.0 else length / PHRASES.size()
	var total := per * PHRASES.size()
	adhan_on = true
	create_tween().tween_property(self, "dawn", 1.0, total).set_trans(Tween.TRANS_SINE)
	for i in PHRASES.size():
		var p: Array = PHRASES[i]
		_show_phrase(p)
		var t0 := adhan_t
		while adhan_t - t0 < per:
			await get_tree().process_frame
			_bar.value = clampf(adhan_t / total, 0.0, 1.0)
	adhan_on = false
	create_tween().tween_property(_sub, "modulate:a", 0.0, 1.2)
	var tw := create_tween()
	tw.tween_property(_lock, "modulate:a", 0.0, 0.6)
	await tw.finished
	_lock.visible = false
	Audio.set_ambience("town", 0.2)


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


func _process(delta: float) -> void:
	time += delta
	if adhan_on:
		adhan_t += delta
	queue_redraw()


func _draw() -> void:
	var vs := get_viewport_rect().size
	var w := vs.x
	var h := vs.y

	# Ciel en bandes : de la nuit vers l'aube.
	var night := [Color("0b1524"), Color("14233a"), Color("1e3350"), Color("24395a"), Color("2b4266")]
	var day := [Color("24395a"), Color("46608a"), Color("8a87a8"), Color("c98f6a"), Color("f2c08a")]
	var bands := [0.0, 0.22, 0.34, 0.44, 0.52, 0.6]
	for i in 5:
		var c: Color = (night[i] as Color).lerp(day[i], dawn)
		draw_rect(Rect2(0, h * bands[i], w, h * (bands[i + 1] - bands[i]) + 1.0), c)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 60:
		var p := Vector2(rng.randf() * w, rng.randf() * h * 0.4)
		draw_circle(p, rng.randf_range(0.8, 2.0), Color(Game.SAND, (1.0 - dawn) * (0.5 + 0.4 * sin(time + i))))

	# Silhouette de Médine : toits plats et palmiers.
	var town := Color("1c2a40")
	var base_y := h * 0.6
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, base_y), Vector2(0, base_y - 40), Vector2(w * 0.12, base_y - 40), Vector2(w * 0.12, base_y - 70),
		Vector2(w * 0.26, base_y - 70), Vector2(w * 0.26, base_y - 30), Vector2(w * 0.4, base_y - 30),
		Vector2(w * 0.4, base_y - 55), Vector2(w * 0.56, base_y - 55), Vector2(w * 0.56, base_y - 25),
		Vector2(w * 0.84, base_y - 25), Vector2(w * 0.84, base_y - 60), Vector2(w, base_y - 60), Vector2(w, base_y)]), town)
	draw_rect(Rect2(0, base_y, w, h - base_y), town)
	Art.palm(self, Vector2(w * 0.07, base_y - 40), 130.0, town, sin(time * 0.9))
	Art.palm(self, Vector2(w * 0.93, base_y - 60), 150.0, town, sin(time * 0.8 + 1.0))
	Art.palm(self, Vector2(w * 0.47, base_y - 55), 110.0, town, sin(time * 1.1 + 2.0))

	# Le toit d'où vient l'appel : seulement une lumière douce et des ondes.
	var src := Vector2(w * 0.68, base_y - 120.0)
	draw_rect(Rect2(src.x - 60.0, src.y, 120.0, base_y - src.y), Color("26364f"))
	var glow := 0.15 + 0.25 * dawn + (0.1 * sin(time * 2.0) if adhan_on else 0.0)
	draw_circle(src, 70.0, Color(Game.FLAME, glow * 0.6))
	draw_circle(src, 34.0, Color(Game.FLAME, glow))
	if adhan_on:
		for i in 4:
			var p := fmod(time * 0.35 + i / 4.0, 1.0)
			draw_arc(src, 40.0 + p * 300.0, PI * 1.05, PI * 1.95, 48, Color(Game.GOLD_LIGHT, 0.6 * (1.0 - p)), 2.5, true)

	# Oiseaux qui s'envolent quand l'appel commence.
	for b in birds:
		var fly := clampf(adhan_t * 0.25, 0.0, 1.0)
		var bp := Vector2(b.x + fly * 400.0 * cos(b.z), b.y - fly * 500.0) + Vector2(0, sin(time * 10.0 + b.z) * 3.0 * fly)
		var wing := 8.0 + 4.0 * sin(time * 14.0 + b.z) * fly
		draw_polyline(PackedVector2Array([bp + Vector2(-wing, -wing * 0.5), bp, bp + Vector2(wing, -wing * 0.5)]), Color("0e1a2b"), 2.5, true)

	# Toit au premier plan, et Selim (jeune homme) vu de dos.
	draw_rect(Rect2(0, h * 0.74, w, h * 0.26), Game.NIGHT)
	draw_rect(Rect2(0, h * 0.74, w, 6), Color("2b3e5c"))
	Art.person(self, Vector2(w * 0.3, selim_y), 260.0, Game.TEAL, Color("3e2612"), Color("e9e1cf"))
