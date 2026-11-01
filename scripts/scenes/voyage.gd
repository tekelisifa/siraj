extends Node2D
## « Ton voyage » : la progression du joueur, sous forme d'un chemin de lanternes.
## Une lanterne par chapitre, dans l'ordre de la vie du Prophète ﷺ, en trois livres :
## - allumée : chapitre terminé (on peut le rejouer) ;
## - qui palpite : chapitre jouable pas encore terminé ;
## - éteinte : chapitre pas encore disponible.
## Un toucher sur une lanterne disponible lance le chapitre.

var time := 0.0


func _ready() -> void:
	Audio.set_ambience("wind", 0.15)
	var root := UI.layer(self)
	var top := UI.vbox(6)
	UI.dock_top(top, 32, 40)
	root.add_child(top)
	top.add_child(UI.label("Ton voyage", 56, Game.GOLD_LIGHT, Game.font_title))
	var done := Game.done_chapters.size()
	var avail := 0
	for c in Game.CHAPTERS:
		if str(c[3]) != "":
			avail += 1
	top.add_child(UI.label("%d chapitre%s terminé%s sur 21 · %d disponibles" % [done, "s" if done > 1 else "", "s" if done > 1 else "", avail], 24, Game.SAND))
	var bar := ProgressBar.new()
	bar.max_value = 21
	bar.value = done
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 14)
	top.add_child(bar)

	var scroll := ScrollContainer.new()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_top = 210
	scroll.offset_bottom = -210
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var path := Chemin.new()
	path.custom_minimum_size = Vector2(get_viewport_rect().size.x, path.total_height())
	scroll.add_child(path)
	# On place la vue sur le prochain chapitre à jouer.
	_scroll_to.call_deferred(scroll, path)

	var back := UI.button("Revenir au menu")
	UI.dock_bottom(back, 40, 40)
	back.pressed.connect(func() -> void: Transition.go("res://scenes/menu.tscn", Game.NIGHT_DEEP))
	root.add_child(back)
	var legend := UI.label("◆ allumée : terminé · palpite : à jouer · éteinte : bientôt", 20, Game.MUTED)
	UI.dock_bottom(legend, 40, 160)
	root.add_child(legend)


func _scroll_to(scroll: ScrollContainer, path: Chemin) -> void:
	await get_tree().process_frame
	scroll.scroll_vertical = int(maxf(0.0, path.node_pos(path.current_index()).y - 260.0))


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	var vs := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vs), Game.NIGHT_DEEP)
	Art.star_pattern(self, Rect2(Vector2.ZERO, vs), 64.0, Color(0.79, 0.64, 0.29, 0.07))


## Le chemin dessiné, avec ses lanternes.
class Chemin extends Control:
	const LIVRES := [
		[1, "Livre I · Les récits du conteur", "vers 570-605 · avant la naissance de Selim"],
		[4, "Livre II · La Mecque", "vers 610-622 · Selim a de 10 à 22 ans"],
		[12, "Livre III · Médine", "622-632 · de l'an 1 à l'an 11 de l'Hégire"],
	]

	const STEP := 150.0
	const HEADER := 160.0
	const TOP := 60.0
	var time := 0.0
	var _press := Vector2.ZERO

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS

	func total_height() -> float:
		return TOP + Game.CHAPTERS.size() * STEP + LIVRES.size() * HEADER + 80.0

	func node_pos(i: int) -> Vector2:
		var headers := 0
		for l in LIVRES:
			if i + 1 >= int(l[0]):
				headers += 1
		var y := TOP + headers * HEADER + i * STEP
		# Zigzag : une lanterne à gauche, la suivante à droite ; le texte prend l'autre côté.
		var x := size.x * (0.27 if i % 2 == 0 else 0.73)
		return Vector2(x, y)

	## Indice du prochain chapitre jouable non terminé (sinon le dernier terminé).
	func current_index() -> int:
		for i in Game.CHAPTERS.size():
			var c: Array = Game.CHAPTERS[i]
			if str(c[3]) != "" and not int(c[0]) in Game.done_chapters and int(c[0]) != 13:
				return i
		return 0

	func _process(delta: float) -> void:
		time += delta
		queue_redraw()

	func _draw() -> void:
		# Chemin doré entre les lanternes.
		var pts := PackedVector2Array()
		for i in Game.CHAPTERS.size():
			pts.append(node_pos(i))
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var lit := int(Game.CHAPTERS[i][0]) in Game.done_chapters and int(Game.CHAPTERS[i + 1][0]) in Game.done_chapters
			var col := Color(Game.GOLD_LIGHT, 0.85) if lit else Color(Game.NIGHT_LINE, 0.9)
			# Courbe en S : descend sous la lanterne, traverse entre deux lignes de texte, remonte.
			var c1 := a + Vector2(0, (b.y - a.y) * 0.7)
			var c2 := b - Vector2(0, (b.y - a.y) * 0.7)
			var curve := PackedVector2Array()
			for k in 21:
				var t := k / 20.0
				var u := 1.0 - t
				curve.append(a * u * u * u + c1 * 3.0 * u * u * t + c2 * 3.0 * u * t * t + b * t * t * t)
			draw_polyline(curve, col, 5.0, true)
		# Titres des livres.
		for l in LIVRES:
			var first := int(l[0]) - 1
			var y := node_pos(first).y - HEADER + 4.0
			draw_string(Game.font_title, Vector2(0, y + 34), str(l[1]), HORIZONTAL_ALIGNMENT_CENTER, size.x, 34, Game.GOLD)
			draw_string(Game.font_body, Vector2(0, y + 64), str(l[2]), HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, Game.MUTED)
		var cur := current_index()
		for i in Game.CHAPTERS.size():
			var c: Array = Game.CHAPTERS[i]
			var p := node_pos(i)
			var n := int(c[0])
			var done := n in Game.done_chapters
			var avail := str(c[3]) != ""
			var pulse := 0.75 + 0.25 * sin(time * 3.0 + i)
			if done:
				draw_circle(p, 48.0, Color(Game.FLAME, 0.18))
				Art.lantern(self, p + Vector2(0, -42), 0.62, 1.0, sin(time * 5.0 + i) * 0.06)
			elif avail:
				draw_circle(p, 44.0 * pulse, Color(Game.FLAME, 0.12))
				Art.lantern(self, p + Vector2(0, -42), 0.62, 0.55 + 0.35 * pulse, 0.0)
			else:
				Art.lantern(self, p + Vector2(0, -42), 0.62, 0.22, 0.0)
			var right := p.x < size.x * 0.5
			var tw := size.x - p.x - 76.0 if right else p.x - 76.0
			var tx := p.x + 58.0 if right else 18.0
			var align := HORIZONTAL_ALIGNMENT_LEFT if right else HORIZONTAL_ALIGNMENT_RIGHT
			var title_col := Game.SAND if avail else Game.MUTED
			draw_string(Game.font_title, Vector2(tx, p.y - 6), "%d · %s" % [n, c[1]], align, tw, 26, title_col)
			var sub := str(c[2])
			if n == 13 and not done:
				sub += " · aperçu"
			elif not avail:
				sub += " · bientôt"
			draw_string(Game.font_body, Vector2(tx, p.y + 22), sub, align, tw, 18, Game.MUTED)
			if i == cur:
				draw_arc(p, 58.0 + 4.0 * sin(time * 3.0), 0.0, TAU, 40, Game.FLAME, 3.0, true)
				draw_string(Game.font_body, Vector2(p.x - 100, p.y + 82), "Tu es ici", HORIZONTAL_ALIGNMENT_CENTER, 200, 20, Game.FLAME)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_press = event.position
			elif event.position.distance_to(_press) < 24.0:
				for i in Game.CHAPTERS.size():
					if node_pos(i).distance_to(event.position) < 70.0:
						var n := int(Game.CHAPTERS[i][0])
						if str(Game.CHAPTERS[i][3]) != "":
							Input.vibrate_handheld(20)
							Game.go_chapter(n, Color("efe2c4") if n <= 3 or n == 5 else Game.SAND_WARM)
						return
