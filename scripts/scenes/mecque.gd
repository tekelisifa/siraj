extends Node2D
## Épisode 1 : Selim, dix ans, dans les ruelles de la Mecque (an 610).
## Le joueur touche le sol pour faire marcher Selim jusqu'à la porte de la voisine.
## Le Prophète ﷺ n'apparaît pas : on entend seulement ce que les gens murmurent.

var time := 0.0
var selim_x := 0.0
var walking := false
var dove_pos := Vector2.ZERO
var dove_flying := false
var neighbor_a := 0.0

var _ground_y := 0.0
var _door_x := 0.0
var _talked := false
var _box: DialogueBox
var _hint: Label
var _words_lbl: Label
var _walk_tw: Tween


func _ready() -> void:
	Audio.set_ambience("town", 0.3)
	var vs := get_viewport_rect().size
	_ground_y = vs.y * 0.6
	_door_x = vs.x * 0.5
	selim_x = vs.x * 0.14
	dove_pos = Vector2(vs.x * 0.36, vs.y * 0.19)

	var root := UI.layer(self)
	_words_lbl = UI.label("", 24, Color("6e4a10"))
	_words_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UI.dock_top(_words_lbl, 32, 50)
	root.add_child(_words_lbl)
	var place := UI.label("La Mecque · matin", 24, Game.INK)
	place.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	UI.dock_top(place, 32, 50)
	root.add_child(place)
	_refresh_words()
	Game.word_added.connect(func(_k: String) -> void: _refresh_words())

	_hint = UI.label("Touche le sol pour faire marcher Selim.\nVa jusqu'à la porte de la voisine.", 30, Game.INK, Game.font_title)
	UI.dock_bottom(_hint, 40, 120)
	root.add_child(_hint)
	UI.fade_in(_hint, 0.8, 1.0)

	_box = DialogueBox.new()
	UI.dock_bottom(_box, 28, 40)
	_box.visible = false
	root.add_child(_box)


func _refresh_words() -> void:
	var n := Game.words.size()
	_words_lbl.text = "Carnet : %d mot%s" % [n, "s" if n > 1 else ""]


func _unhandled_input(event: InputEvent) -> void:
	if _talked or Transition.busy:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p := get_global_mouse_position()
		if p.y > _ground_y - 120.0:
			_walk_to(clampf(p.x, 60.0, get_viewport_rect().size.x - 60.0))


func _walk_to(x: float) -> void:
	if _walk_tw:
		_walk_tw.kill()
	walking = true
	var dur := absf(x - selim_x) / 260.0
	_walk_tw = create_tween()
	_walk_tw.tween_property(self, "selim_x", x, maxf(dur, 0.2))
	_walk_tw.tween_callback(_arrived)


func _arrived() -> void:
	walking = false
	if not _talked and absf(selim_x - _door_x) < 90.0:
		_talked = true
		_conversation()


func _conversation() -> void:
	create_tween().tween_property(_hint, "modulate:a", 0.0, 0.3)
	create_tween().tween_property(self, "neighbor_a", 1.0, 0.6)
	await get_tree().create_timer(0.5).timeout
	await _box.say("Oumm Sâlih, la voisine", "As-salâmu ʿalaykum, yâ Selîm ! Tu es bien matinal aujourd'hui.", ["salam"])
	_box.show_text("", "[i]Comment Selim répond-il ?[/i]")
	var choice := await _box.ask(["Répondre « Wa ʿalaykumu s-salâm »", "Lui faire un signe de la main"])
	if choice == 1:
		await _box.say("Oumm Sâlih, la voisine", "Ici, on se salue avec des mots de paix, mon garçon. Réponds-moi : Wa ʿalaykumu s-salâm !", ["wa_salam"])
	else:
		Game.add_word("wa_salam")
		await _box.say("Selim", "Wa ʿalaykumu s-salâm, Oumm Sâlih !", ["wa_salam"])
	await _box.say("Oumm Sâlih, la voisine", "Tiens, prends ces dattes. Et n'oublie pas de dire Bismillâh avant de manger.", ["bismillah"])
	await _box.say("Selim", "Bismillâh… Mmm ! Alhamdulillâh !", ["bismillah", "alhamdulillah"])
	await _box.say("Oumm Sâlih, la voisine", "[i](Elle baisse la voix.)[/i] As-tu entendu ce que l'on raconte ? Muhammad, fils de ʿAbdallâh ﷺ, celui que toute la Mecque appelle Al-Amîn…", ["amin"])
	await _box.say("Oumm Sâlih, la voisine", "Il s'isolait pour prier dans la grotte de Hira. On dit que l'ange Jibrîl lui est apparu, et lui a dit : « Iqraʾ ! »", ["iqra"])
	await _box.say("Selim", "Iqraʾ… « Lis ! »  Al-Amîn, l'homme le plus honnête de la Mecque… Je veux comprendre ce qui se passe.")
	await _box.say("Le conteur", "[i]Ce jour-là, mon petit, je ne savais pas encore que toute ma vie allait suivre ce murmure.[/i]")
	_dove_flies()
	_box.show_text("", "[i]La colombe s'envole au-dessus des toits.[/i]")
	await _box.ask(["Suivre la colombe"])
	Transition.go("res://scenes/aube.tscn", Game.NIGHT_DEEP, "Douze ans plus tard…\nMédine, an 1 de l'Hégire")


func _dove_flies() -> void:
	dove_flying = true
	var vs := get_viewport_rect().size
	var tw := create_tween()
	tw.tween_property(self, "dove_pos", Vector2(vs.x * 0.7, vs.y * 0.08), 1.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "dove_pos", Vector2(vs.x + 80.0, -40.0), 1.4)


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	var vs := get_viewport_rect().size
	var w := vs.x
	var h := vs.y
	var g := _ground_y

	draw_rect(Rect2(Vector2.ZERO, vs), Game.SAND_WARM)
	draw_circle(Vector2(w * 0.82, h * 0.1), 56.0, Color("fbe3a8"))
	# Montagnes au loin.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, h * 0.26), Vector2(w * 0.18, h * 0.17), Vector2(w * 0.35, h * 0.24),
		Vector2(w * 0.55, h * 0.15), Vector2(w * 0.8, h * 0.23), Vector2(w, h * 0.18), Vector2(w, h * 0.3), Vector2(0, h * 0.3)]), Color("e3c185"))

	# Maisons de la ruelle.
	draw_rect(Rect2(0, h * 0.13, w * 0.27, g - h * 0.13), Color("d9a866"))
	draw_rect(Rect2(w * 0.73, h * 0.16, w * 0.27, g - h * 0.16), Color("c99355"))
	draw_rect(Rect2(w * 0.27, h * 0.22, w * 0.46, g - h * 0.22), Color("e8c185"))
	draw_rect(Rect2(w * 0.27, h * 0.215, w * 0.46, 10), Color("d9a866"))
	for p in [Vector2(w * 0.08, h * 0.22), Vector2(w * 0.17, h * 0.33), Vector2(w * 0.83, h * 0.25), Vector2(w * 0.9, h * 0.38)]:
		_arch(p, 34.0, 52.0, Color("7a4e1e"))

	# Porte de la voisine.
	_arch(Vector2(_door_x, g - 220.0), 130.0, 220.0, Color("5c3a1e"))
	_arch(Vector2(_door_x, g - 206.0), 110.0, 206.0, Color("3e2612"))
	if neighbor_a > 0.0:
		Art.person(self, Vector2(_door_x, g - 4.0), 170.0, Art.fade(Color("6b3f4a"), neighbor_a), Color("3e2a1a"), Art.fade(Color("2b3e5c"), neighbor_a), true)

	# Sol.
	draw_rect(Rect2(0, g, w, h - g), Color("d7b074"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 24:
		draw_circle(Vector2(rng.randf() * w, g + 20.0 + rng.randf() * (h - g)), rng.randf_range(2.0, 5.0), Color("c49a5c"))

	# Colombe.
	var flap := sin(time * (16.0 if dove_flying else 2.0))
	var hop := 0.0 if dove_flying else absf(sin(time * 1.3)) * -3.0
	Art.dove(self, dove_pos + Vector2(0, hop), 1.3, flap if dove_flying else flap * 0.15)

	# Selim, dix ans, vu de dos.
	var bob := absf(sin(time * 10.0)) * -6.0 if walking else 0.0
	draw_colored_polygon(Art.ellipse(Vector2(selim_x, g + 110.0), 40.0, 10.0), Color(0, 0, 0, 0.12))
	Art.person(self, Vector2(selim_x, g + 110.0 + bob), 190.0, Game.TEAL, Color("3e2612"), Color("e9e1cf"))


func _arch(top_center: Vector2, width: float, height: float, color: Color) -> void:
	var r := width * 0.5
	var pts := PackedVector2Array()
	pts.append(top_center + Vector2(-r, height))
	for i in 17:
		var a := PI + PI * i / 16.0
		pts.append(top_center + Vector2(cos(a) * r, r + sin(a) * r))
	pts.append(top_center + Vector2(r, height))
	draw_colored_polygon(pts, color)
