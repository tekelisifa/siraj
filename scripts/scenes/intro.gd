extends Node2D
## Ouverture animée :
## 1. Le ciel étoilé et la lampe : « Sirâj ».
## 2. La frise des prophètes (paix sur eux), d'Âdam à Muhammad ﷺ : un même message transmis.
## 3. Zoom sur la vie de Muhammad ﷺ (570-632).
## 4. Zoom sur le point de départ de l'histoire : « Tu es ici », la Mecque, an 610.

const PROPHETS := ["Âdam", "Nûh", "Ibrâhîm", "Mûsâ", "Dâwûd", "ʿÎsâ", "Muhammad ﷺ"]
const EVENTS := [
	[570, "Naissance", "Année de l'Éléphant"],
	[610, "Révélation", "Grotte de Hira"],
	[622, "Hégire", "La Mecque → Médine"],
	[632, "Retour à Dieu", "Médine"],
]
const SPACING := 150.0
const LAST_WX := 900.0
const YEAR_SCALE := 0.45

var time := 0.0
var stars: Array[Vector4] = []

var stars_a := 0.0
var title_a := 0.0
var line_a := 0.0
var reveal := 0.0
var life_a := 0.0
var here_a := 0.0

var view_center := 450.0
var view_scale := 0.7

var _ready_to_start := false
var _finishing := false
var _caption: Label
var _prompt: Label
var _skip: Button


func _ready() -> void:
	var vs := get_viewport_rect().size
	for i in 140:
		stars.append(Vector4(randf() * vs.x, randf() * vs.y, randf() * TAU, randf_range(0.8, 2.4)))
	view_scale = (vs.x - 280.0) / LAST_WX
	view_center = LAST_WX * 0.5
	_build_ui()
	Audio.set_ambience("wind", 0.25)
	_play()


func _build_ui() -> void:
	var root := UI.layer(self)

	_caption = UI.label("", 34, Game.SAND, Game.font_title)
	UI.dock_bottom(_caption, 48, 260)
	_caption.modulate.a = 0.0
	root.add_child(_caption)

	_prompt = UI.label("Touche l'écran pour commencer", 28, Game.GOLD_LIGHT)
	UI.dock_bottom(_prompt, 48, 110)
	_prompt.modulate.a = 0.0
	root.add_child(_prompt)

	_skip = UI.button("Passer", false)
	_skip.custom_minimum_size = Vector2(170, 80)
	_skip.add_theme_font_size_override("font_size", 24)
	_skip.anchor_left = 1.0
	_skip.anchor_right = 1.0
	_skip.offset_left = -200
	_skip.offset_right = -30
	_skip.offset_top = 50
	_skip.offset_bottom = 130
	_skip.pressed.connect(_finish)
	root.add_child(_skip)


func _play() -> void:
	var vs := get_viewport_rect().size
	var tw := create_tween()
	# 1. Le ciel et la lampe.
	tw.tween_property(self, "stars_a", 1.0, 1.5)
	tw.tween_property(self, "title_a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
	tw.tween_interval(2.0)
	tw.tween_property(self, "title_a", 0.0, 1.2)

	# 2. La chaîne des prophètes.
	tw.tween_callback(_say.bind("Depuis Âdam, Dieu a envoyé des prophètes, paix sur eux, avec un même message : adorer Dieu, l'Unique."))
	tw.tween_property(self, "line_a", 1.0, 1.2)
	tw.tween_property(self, "reveal", float(PROPHETS.size()), 5.5)
	tw.tween_interval(2.0)

	# 3. Zoom sur la vie de Muhammad ﷺ.
	tw.tween_callback(_say.bind("Le dernier d'entre eux est Muhammad ﷺ. Sa vie, sur 63 années, a changé le monde."))
	var life_scale := (vs.x - 200.0) / ((632 - 570) * YEAR_SCALE)
	var life_center := _wx(601)
	tw.tween_method(_zoom.bind(view_center, life_center, view_scale, life_scale), 0.0, 1.0, 3.5)
	tw.parallel().tween_property(self, "life_a", 1.0, 1.6).set_delay(1.8)
	tw.tween_interval(3.0)

	# 4. Zoom sur « Tu es ici ».
	tw.tween_callback(_say.bind("Notre histoire commence ici. La Mecque, an 610. Selim a dix ans… et il va tout voir de ses propres yeux."))
	tw.tween_method(_zoom.bind(life_center, _wx(610), life_scale, life_scale * 2.6), 0.0, 1.0, 2.8)
	tw.parallel().tween_property(self, "here_a", 1.0, 1.2).set_delay(1.4)
	tw.tween_interval(1.5)
	tw.tween_callback(_ready_prompt)


func _zoom(t: float, from_c: float, to_c: float, from_s: float, to_s: float) -> void:
	var e := smoothstep(0.0, 1.0, t)
	view_scale = exp(lerpf(log(from_s), log(to_s), e))
	# Le centre suit l'échelle pour que le point visé reste stable (zoom naturel).
	var k := (1.0 / view_scale - 1.0 / from_s) / (1.0 / to_s - 1.0 / from_s)
	view_center = lerpf(from_c, to_c, k)


func _say(text: String) -> void:
	var tw := create_tween()
	tw.tween_property(_caption, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func() -> void: _caption.text = text)
	tw.tween_property(_caption, "modulate:a", 1.0, 0.6)


func _ready_prompt() -> void:
	_ready_to_start = true
	create_tween().tween_property(_skip, "modulate:a", 0.0, 0.4)
	var tw := create_tween().set_loops()
	tw.tween_property(_prompt, "modulate:a", 1.0, 0.9)
	tw.tween_property(_prompt, "modulate:a", 0.35, 0.9)


func _unhandled_input(event: InputEvent) -> void:
	if _ready_to_start and event is InputEventMouseButton and event.pressed:
		_finish()


func _finish() -> void:
	if _finishing:
		return
	_finishing = true
	Input.vibrate_handheld(25)
	var next := "res://scenes/menu.tscn" if Game.sound_ack else "res://scenes/sound_check.tscn"
	Transition.go(next, Game.NIGHT_DEEP)


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


# --- Coordonnées de la frise ---

func _wx(year: float) -> float:
	return LAST_WX + (year - 601.0) * YEAR_SCALE


func _sx(wx: float) -> float:
	return (wx - view_center) * view_scale + get_viewport_rect().size.x * 0.5


# --- Dessin ---

func _draw() -> void:
	var vs := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vs), Game.NIGHT_DEEP)
	for s in stars:
		var tw := 0.45 + 0.55 * sin(time * 1.3 + s.z)
		draw_circle(Vector2(s.x, s.y), s.w, Color(Game.SAND, stars_a * tw * 0.8))

	if title_a > 0.0:
		_draw_title(vs)
	if line_a > 0.0:
		_draw_timeline(vs)


func _draw_title(vs: Vector2) -> void:
	var c := Vector2(vs.x * 0.5, vs.y * 0.2)
	Art.lantern(self, c, 1.25, title_a, sin(time * 7.0) * 0.5 + sin(time * 13.0) * 0.5)
	UI.draw_text(self, Game.font_arabic, vs.x * 0.5, vs.y * 0.56, "سِرَاج", 84, Art.fade(Game.GOLD_LIGHT, title_a))
	UI.draw_text(self, Game.font_title, vs.x * 0.5, vs.y * 0.65, "Sirâj", 120, Art.fade(Game.SAND, title_a))
	UI.draw_text(self, Game.font_title, vs.x * 0.5, vs.y * 0.70, "Le voyage de Selim", 44, Art.fade(Game.GOLD_LIGHT, title_a))


func _draw_timeline(vs: Vector2) -> void:
	var y := vs.y * 0.42
	var gold := Art.fade(Game.GOLD, line_a)
	draw_line(Vector2(_sx(0.0), y), Vector2(_sx(LAST_WX), y), gold, 3.0, true)

	# Prophètes : points de lumière.
	var label_a := clampf(1.0 - (view_scale - 1.5) / 3.0, 0.0, 1.0)
	for i in PROPHETS.size():
		var r := clampf(reveal - i, 0.0, 1.0)
		if r <= 0.0:
			continue
		var x := _sx(i * SPACING)
		var last := i == PROPHETS.size() - 1
		var point_a := r * line_a * (1.0 - life_a if last else 1.0)
		var pulse := 1.0 + (0.15 * sin(time * 3.0) if last else 0.0)
		draw_circle(Vector2(x, y), (34.0 if last else 22.0) * pulse, Art.fade(Game.FLAME, 0.18 * point_a))
		draw_circle(Vector2(x, y), (13.0 if last else 9.0), Art.fade(Game.FLAME, point_a))
		var above := i % 2 == 0
		var ly := y - 44.0 if above else y + 64.0
		if last:
			ly = y - 96.0
			draw_line(Vector2(x, y - 36.0), Vector2(x, y - 86.0), Art.fade(Game.GOLD_LIGHT, r * label_a * 0.6), 1.5)
		UI.draw_text(self, Game.font_body, x, ly, PROPHETS[i], 30 if last else 26, Art.fade(Game.GOLD_LIGHT if last else Game.SAND, r * label_a))

	# La vie de Muhammad ﷺ.
	if life_a > 0.0:
		var x0 := _sx(_wx(570))
		var x1 := _sx(_wx(632))
		draw_line(Vector2(x0, y), Vector2(x1, y), Art.fade(Game.GOLD_LIGHT, life_a), 8.0, true)
		var ev_label_a := life_a * (1.0 - here_a)
		for j in EVENTS.size():
			var ev: Array = EVENTS[j]
			var ex := _sx(_wx(float(ev[0])))
			draw_circle(Vector2(ex, y), 16.0, Art.fade(Game.NIGHT_DEEP, life_a))
			draw_circle(Vector2(ex, y), 12.0, Art.fade(Game.FLAME, life_a))
			# Étiquettes réparties sur des emplacements fixes, reliées au vrai point
			# par un trait : la frise reste à l'échelle sans que les textes se chevauchent.
			var slot_x := vs.x * (0.17 + 0.22 * j)
			var up := j % 2 == 0
			var base := y - 190.0 if up else y + 120.0
			var link_end := Vector2(slot_x, base + 92.0) if up else Vector2(slot_x, base - 38.0)
			draw_line(Vector2(ex, y + (-18.0 if up else 18.0)), link_end, Art.fade(Game.GOLD, ev_label_a * 0.7), 1.5, true)
			UI.draw_text(self, Game.font_body, slot_x, base, str(ev[0]), 28, Art.fade(Game.GOLD_LIGHT, ev_label_a))
			UI.draw_text(self, Game.font_title, slot_x, base + 40.0, str(ev[1]), 30, Art.fade(Game.SAND, ev_label_a))
			UI.draw_text(self, Game.font_body, slot_x, base + 70.0, str(ev[2]), 19, Art.fade(Game.MUTED, ev_label_a))

	# Tu es ici.
	if here_a > 0.0:
		var hx := _sx(_wx(610))
		var ring := 30.0 + 10.0 * sin(time * 3.2)
		draw_arc(Vector2(hx, y), ring, 0.0, TAU, 48, Art.fade(Game.FLAME, here_a), 3.0, true)
		draw_arc(Vector2(hx, y), ring + 18.0, 0.0, TAU, 48, Art.fade(Game.FLAME, here_a * 0.35), 2.0, true)
		draw_line(Vector2(hx, y - ring - 4.0), Vector2(hx, y - 150.0), Art.fade(Game.GOLD_LIGHT, here_a), 2.0)
		UI.draw_text(self, Game.font_title, hx, y - 168.0, "Tu es ici", 54, Art.fade(Game.FLAME, here_a))
		UI.draw_text(self, Game.font_body, hx, y + 100.0, "La Mecque · an 610", 32, Art.fade(Game.SAND, here_a))
