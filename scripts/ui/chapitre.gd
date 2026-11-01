class_name Chapitre
extends Node2D
## Base commune des chapitres « racontés » (livre I et suivants) :
## - un décor d'enluminure : parchemin, cadre doré, et une vignette animée au centre ;
## - la boîte de dialogue (avec repères de sources), le menu de pause et le bandeau de lieu ;
## - une carte de l'Arabie qui s'ouvre au bon moment ;
## - un écran de verset (traduction du sens, paysage seul, sans personnage) ;
## - la carte de fin « Ce que Selim retient » ;
## - de petits gestes : faire glisser le doigt le long d'une route, toucher une cible.
##
## Chaque chapitre hérite de cette classe, dessine sa vignette dans `_draw_vignette`
## et écrit son récit dans `_story`.

const PARCHMENT := Color("efe2c4")
const PARCHMENT_DARK := Color("d9c296")

var time := 0.0
var vignette := ""
var vignette_a := 1.0
var root: Control
var box: DialogueBox
var pause: PauseMenu
var carte: Carte
var _hint: Label
var _drag_cb: Callable
var _drag_left := 0.0
var _drag_total := 1.0
var _tap_target := Rect2()
var _tap_waiting := false

signal drag_done
signal target_tapped


## À redéfinir : numéro du chapitre, année (pour la frise), lieu et texte du menu de pause.
func chapter_info() -> Dictionary:
	return {"num": 0, "year": 570, "where": "", "here": ""}


func chapter_num() -> int:
	return int(chapter_info().get("num", 0))


func _ready() -> void:
	var info := chapter_info()
	root = UI.layer(self)
	carte = Carte.new()
	carte.anchor_right = 1.0
	carte.offset_left = 36
	carte.offset_right = -36
	carte.offset_top = 150
	carte.offset_bottom = 150 + get_viewport_rect().size.y * 0.5
	carte.visible = false
	root.add_child(carte)

	_hint = UI.label("", 26, Game.INK, Game.font_title)
	_hint.anchor_right = 1.0
	_hint.anchor_top = 0.0
	_hint.offset_left = 40
	_hint.offset_right = -40
	_hint.offset_top = 96
	_hint.offset_bottom = 146
	_hint.modulate.a = 0.0
	root.add_child(_hint)

	# Numéro et titre du chapitre, toujours visibles en haut.
	var n := chapter_num()
	if n > 0:
		var c := Game.chapter(n)
		var top := UI.label("Chapitre %d · %s" % [n, c[1]], 24, Game.INK, Game.font_title)
		top.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		UI.dock_top(top, 36, 46)
		top.offset_right = -130
		root.add_child(top)

	box = DialogueBox.new()
	UI.dock_bottom(box, 28, 40)
	box.visible = false
	root.add_child(box)
	pause = PauseMenu.attach(self, int(info["year"]), str(info["where"]), str(info["here"]))
	_story()


## À redéfinir : le déroulé du chapitre.
func _story() -> void:
	pass


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


# --- Décor ---

func vignette_rect() -> Rect2:
	var vs := get_viewport_rect().size
	return Rect2(36, 150, vs.x - 72, vs.y * 0.5)


func _draw() -> void:
	var vs := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vs), PARCHMENT)
	# Bords assombris du parchemin.
	for i in 10:
		var a := 0.035 * (10 - i)
		draw_rect(Rect2(Vector2(i * 6.0, i * 6.0), vs - Vector2(i * 12.0, i * 12.0)), Color(0.55, 0.4, 0.15, a), false, 6.0)
	Art.star_pattern(self, Rect2(0, 0, vs.x, 120), 60.0, Color(0.79, 0.64, 0.29, 0.22))
	Art.star_pattern(self, Rect2(0, vs.y - 90, vs.x, 90), 60.0, Color(0.79, 0.64, 0.29, 0.18))
	var r := vignette_rect()
	if vignette != "" and not carte.visible:
		draw_set_transform(Vector2.ZERO)
		_draw_vignette(r)
		# Cadre doré de l'enluminure.
		draw_rect(r, Game.GOLD, false, 5.0)
		draw_rect(r.grow(10.0), Color(Game.GOLD, 0.5), false, 2.0)
		for c in [r.position, r.position + Vector2(r.size.x, 0), r.end, r.position + Vector2(0, r.size.y)]:
			draw_circle(c, 9.0, Game.GOLD)


## À redéfinir : dessin de la vignette en cours (`vignette`).
func _draw_vignette(_r: Rect2) -> void:
	pass


# --- Aides au dessin ---

func sky(r: Rect2, top: Color, bottom: Color) -> void:
	var n := 12
	for i in n:
		var c := top.lerp(bottom, float(i) / (n - 1))
		draw_rect(Rect2(r.position.x, r.position.y + r.size.y * i / n, r.size.x, r.size.y / n + 1.0), c)


func mountains(r: Rect2, base_y: float, height: float, col: Color, seed_v := 1) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var pts := PackedVector2Array([Vector2(r.position.x, r.end.y), Vector2(r.position.x, base_y)])
	var x := r.position.x
	while x < r.end.x:
		x += rng.randf_range(40.0, 90.0)
		pts.append(Vector2(minf(x, r.end.x), base_y - rng.randf_range(0.3, 1.0) * height))
		x += rng.randf_range(30.0, 70.0)
		pts.append(Vector2(minf(x, r.end.x), base_y - rng.randf_range(0.0, 0.3) * height))
	pts.append(Vector2(r.end.x, base_y))
	pts.append(Vector2(r.end.x, r.end.y))
	draw_colored_polygon(pts, col)


func kaaba(base: Vector2, s: float) -> void:
	draw_rect(Rect2(base + Vector2(-s * 0.5, -s * 0.9), Vector2(s, s * 0.9)), Color("1c1712"))
	draw_colored_polygon(PackedVector2Array([base + Vector2(s * 0.5, -s * 0.9), base + Vector2(s * 0.75, -s * 0.78), base + Vector2(s * 0.75, s * 0.1), base + Vector2(s * 0.5, 0)]), Color("2a231b"))


func stars(r: Rect2, n: int, a := 1.0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in n:
		var p := Vector2(r.position.x + rng.randf() * r.size.x, r.position.y + rng.randf() * r.size.y * 0.6)
		var tw := 0.6 + 0.4 * sin(time * 2.0 + i)
		draw_circle(p, rng.randf_range(1.0, 2.4), Color(1, 0.96, 0.85, a * tw))


# --- Interface du récit ---

func banner(place: String, details: String) -> void:
	var n := chapter_num()
	if n > 0:
		details = "Chapitre %d · %s\n%s" % [n, Game.chapter(n)[1], details]
	await UI.place_banner(root, place, details, false)


## Fin du chapitre : progression enregistrée, puis chapitre suivant (ou « À suivre »).
func finish() -> void:
	var n := chapter_num()
	Game.mark_done(n)
	var nxt := Game.next_playable(n)
	if nxt > 0:
		Game.go_chapter(nxt, PARCHMENT)
	else:
		Transition.go("res://scenes/a_suivre.tscn", Game.NIGHT_DEEP)


func hint(text: String) -> void:
	_hint.text = text
	var tw := create_tween()
	tw.tween_property(_hint, "modulate:a", 1.0 if text != "" else 0.0, 0.4)


func show_vignette(name: String) -> void:
	vignette = name
	carte.visible = false


func show_map(places: Array, highlight := "", lat := 24.0, lon := 42.0, span := 22.0) -> void:
	carte.places.clear()
	for p in places:
		carte.places.append(str(p))
	carte.highlight = highlight
	carte.routes.clear()
	carte.zones.clear()
	carte.light = 0.0
	carte.view_lat = lat
	carte.view_lon = lon
	carte.view_span = span
	carte.visible = true
	UI.fade_in(carte, 0.6)


## Fait glisser la vue de la carte.
func move_map(lat: float, lon: float, span: float, dur := 1.6) -> void:
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	tw.tween_property(carte, "view_lat", lat, dur)
	tw.tween_property(carte, "view_lon", lon, dur)
	tw.tween_property(carte, "view_span", span, dur)
	await tw.finished


## Le joueur fait glisser son doigt sur l'écran pour faire avancer quelque chose
## (une route sur la carte, une caravane…). `on_progress` reçoit une valeur de 0 à 1.
func drag_progress(text: String, on_progress: Callable, length := 1400.0) -> void:
	hint(text)
	_drag_cb = on_progress
	_drag_left = length
	_drag_total = length
	await drag_done
	hint("")


## Attend que le joueur touche une zone de l'écran.
func wait_tap(target: Rect2, text: String) -> void:
	hint(text)
	_tap_target = target
	_tap_waiting = true
	await target_tapped
	hint("")


func _unhandled_input(event: InputEvent) -> void:
	if _drag_left > 0.0 and event is InputEventScreenDrag:
		_drag_left -= event.relative.length()
		_drag_cb.call(clampf(1.0 - _drag_left / _drag_total, 0.0, 1.0))
		if _drag_left <= 0.0:
			_drag_left = 0.0
			Input.vibrate_handheld(30)
			drag_done.emit()
	elif _drag_left > 0.0 and event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		_drag_left -= event.relative.length()
		_drag_cb.call(clampf(1.0 - _drag_left / _drag_total, 0.0, 1.0))
		if _drag_left <= 0.0:
			_drag_left = 0.0
			Input.vibrate_handheld(30)
			drag_done.emit()
	elif _tap_waiting and event is InputEventMouseButton and event.pressed:
		if _tap_target.grow(30.0).has_point(event.position):
			_tap_waiting = false
			Input.vibrate_handheld(30)
			target_tapped.emit()


## Écran de verset : paysage seul, texte de la traduction du sens qui apparaît ligne
## par ligne, sans voix ni musique. Les contrôles et la pause sont figés.
func verse(title: String, ref_key: String, lines: Array) -> void:
	box.visible = false
	pause.locked = true
	Game.note_ref(ref_key)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Game.NIGHT, 0.9)
	sb.border_color = Game.GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(30)
	sb.set_content_margin_all(30)
	panel.add_theme_stylebox_override("panel", sb)
	UI.dock_bottom(panel, 28, 40)
	root.add_child(panel)
	var v := UI.vbox(14)
	panel.add_child(v)
	v.add_child(UI.label(title, 24, Game.GOLD_LIGHT))
	var labels: Array[Label] = []
	for l in lines:
		var lab := UI.label(str(l), 32, Game.SAND, Game.font_title)
		lab.modulate.a = 0.0
		v.add_child(lab)
		labels.append(lab)
	var note := UI.label("Traduction du sens, pas le texte du Coran. Référence : %s" % Game.ref(ref_key).get("court", ""), 20, Game.MUTED)
	note.modulate.a = 0.0
	v.add_child(note)
	var tw := create_tween()
	for lab in labels:
		tw.tween_property(lab, "modulate:a", 1.0, 0.9)
		tw.tween_interval(1.6)
	tw.tween_property(note, "modulate:a", 1.0, 0.6)
	await tw.finished
	var cont := UI.button("Continuer", false)
	cont.custom_minimum_size = Vector2(0, 84)
	v.add_child(cont)
	UI.fade_in(cont, 0.4)
	await cont.pressed
	panel.queue_free()
	pause.locked = false


## Carte de fin de chapitre : « Ce que Selim retient », et les mots ajoutés au carnet.
func recap(points: Array, words: Array = []) -> void:
	box.visible = false
	for w in words:
		Game.add_word(str(w))
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Game.NIGHT, 0.95)
	sb.border_color = Game.GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(30)
	sb.set_content_margin_all(32)
	panel.add_theme_stylebox_override("panel", sb)
	panel.anchor_right = 1.0
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = 36
	panel.offset_right = -36
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_child(panel)
	var v := UI.vbox(16)
	panel.add_child(v)
	v.add_child(UI.label("Ce que Selim retient", 44, Game.GOLD_LIGHT, Game.font_title))
	for p in points:
		var l := UI.label("◆  " + str(p), 27, Game.SAND)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(l)
	if not words.is_empty():
		v.add_child(UI.label("+ %d mot(s) dans ton carnet" % words.size(), 22, Game.TEAL_LIGHT))
	v.add_child(UI.label("Toutes les sources : bouton pause, « Sources de ce passage ».", 20, Game.MUTED))
	var cont := UI.button("Continuer le voyage")
	cont.custom_minimum_size = Vector2(0, 92)
	v.add_child(cont)
	UI.fade_in(panel, 0.6)
	await cont.pressed
	panel.queue_free()
