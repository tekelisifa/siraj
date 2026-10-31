class_name Art
extends RefCounted
## Dessins vectoriels du jeu (lanternes, personnages fictifs vus de dos, colombe, palmiers…).
## Règle du projet : aucun prophète ni Compagnon n'est jamais dessiné.


static func ellipse(c: Vector2, rx: float, ry: float, n := 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


static func fade(col: Color, a: float) -> Color:
	return Color(col.r, col.g, col.b, col.a * a)


## Lanterne dorée. `top` = point d'accroche, `s` = échelle (1.0 ≈ 190 px de haut).
static func lantern(ci: CanvasItem, top: Vector2, s := 1.0, a := 1.0, flicker := 0.0) -> void:
	var gold := fade(Game.GOLD, a)
	var flame := fade(Game.FLAME, a)
	var mid := top + Vector2(0, 96) * s
	ci.draw_circle(mid, 95.0 * s * (1.0 + flicker * 0.06), fade(Game.FLAME, 0.07 * a))
	ci.draw_circle(mid, 62.0 * s * (1.0 + flicker * 0.04), fade(Game.FLAME, 0.10 * a))
	ci.draw_line(top, top + Vector2(0, 22) * s, gold, 3.0 * s)
	ci.draw_colored_polygon(_pts(top, s, [[-16, 22], [16, 22], [24, 40], [-24, 40]]), gold)
	ci.draw_colored_polygon(_pts(top, s, [[-24, 40], [24, 40], [34, 120], [0, 150], [-34, 120]]), fade(Game.NIGHT_BLUE, a))
	ci.draw_colored_polygon(_pts(top, s, [[-12, 52], [12, 52], [20, 116], [0, 134], [-20, 116]]), flame)
	ci.draw_colored_polygon(ellipse(mid, 10.0 * s, (18.0 + flicker * 2.0) * s), fade(Game.FLAME_CORE, a))
	ci.draw_colored_polygon(_pts(top, s, [[-34, 120], [0, 150], [34, 120], [34, 132], [0, 162], [-34, 132]]), gold)
	ci.draw_circle(top + Vector2(0, 176) * s, 6.0 * s, gold)


## Petite lanterne suspendue (guirlande de la veillée, rues de Médine).
static func small_lantern(ci: CanvasItem, hook: Vector2, s := 1.0, a := 1.0, flicker := 0.0) -> void:
	ci.draw_line(hook, hook + Vector2(0, 14) * s, fade(Color("5a6b82"), a), 2.0)
	var c := hook + Vector2(0, 30) * s
	ci.draw_circle(c, 30.0 * s * (1.0 + flicker * 0.08), fade(Game.FLAME, 0.15 * a))
	ci.draw_colored_polygon(_pts(hook, s, [[-10, 14], [10, 14], [12, 44], [0, 50], [-12, 44]]), fade(Game.FLAME, a))
	ci.draw_colored_polygon(_pts(hook, s, [[-8, 10], [8, 10], [10, 16], [-10, 16]]), fade(Game.GOLD, a))


static func _pts(origin: Vector2, s: float, coords: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in coords:
		out.append(origin + Vector2(p[0], p[1]) * s)
	return out


## Personnage fictif vu de dos. `feet` = point au sol, `h` = hauteur totale.
## `veil` : coiffe couvrante (femme). `beard` : barbe blanche visible de profil (vieil homme).
static func person(ci: CanvasItem, feet: Vector2, h: float, robe: Color, head: Color, wrap: Color, veil := false, beard := false) -> void:
	var w := h * 0.36
	var head_r := h * 0.12
	var sy := feet.y - h * 0.74
	var body := PackedVector2Array([
		Vector2(feet.x - w * 0.62, feet.y),
		Vector2(feet.x - w * 0.52, sy + h * 0.14),
		Vector2(feet.x - w * 0.34, sy),
		Vector2(feet.x + w * 0.34, sy),
		Vector2(feet.x + w * 0.52, sy + h * 0.14),
		Vector2(feet.x + w * 0.62, feet.y),
	])
	ci.draw_colored_polygon(body, robe)
	var hc := Vector2(feet.x, sy - head_r * 0.85)
	if veil:
		ci.draw_colored_polygon(ellipse(hc + Vector2(0, head_r * 0.25), head_r * 1.25, head_r * 1.35), wrap)
	else:
		ci.draw_circle(hc, head_r, head)
		ci.draw_arc(hc, head_r * 0.8, PI * 1.02, TAU * 0.99, 18, wrap, head_r * 0.6)
	if beard:
		ci.draw_colored_polygon(PackedVector2Array([
			hc + Vector2(head_r * 0.5, head_r * 0.3),
			hc + Vector2(head_r * 1.05, head_r * 0.4),
			hc + Vector2(head_r * 0.7, head_r * 1.5),
		]), Color("e9e1cf"))


## Personnage assis (veillée).
static func seated(ci: CanvasItem, ground: Vector2, h: float, robe: Color, head: Color, wrap: Color, beard := false) -> void:
	var w := h * 0.55
	var body := PackedVector2Array([
		ground + Vector2(-w * 0.55, 0),
		ground + Vector2(-w * 0.45, -h * 0.45),
		ground + Vector2(-w * 0.25, -h * 0.68),
		ground + Vector2(w * 0.25, -h * 0.68),
		ground + Vector2(w * 0.45, -h * 0.45),
		ground + Vector2(w * 0.6, 0),
	])
	ci.draw_colored_polygon(body, robe)
	var head_r := h * 0.13
	var hc := ground + Vector2(0, -h * 0.68 - head_r * 0.85)
	ci.draw_circle(hc, head_r, head)
	ci.draw_arc(hc, head_r * 0.8, PI * 1.02, TAU * 0.99, 18, wrap, head_r * 0.6)
	if beard:
		ci.draw_colored_polygon(PackedVector2Array([
			hc + Vector2(head_r * 0.4, head_r * 0.2),
			hc + Vector2(head_r * 1.1, head_r * 0.4),
			hc + Vector2(head_r * 0.6, head_r * 1.7),
		]), Color("e9e1cf"))


## Colombe. `flap` entre -1 et 1 pour animer l'aile.
static func dove(ci: CanvasItem, pos: Vector2, s := 1.0, flap := 0.0, facing := 1.0) -> void:
	var white := Color("fbf7ee")
	var shade := Color("d8cfbd")
	ci.draw_colored_polygon(ellipse(pos, 22.0 * s, 13.0 * s, 20), white)
	var head := pos + Vector2(20.0 * facing, -10.0) * s
	ci.draw_circle(head, 9.0 * s, white)
	ci.draw_colored_polygon(PackedVector2Array([
		head + Vector2(8.0 * facing, -1.0) * s,
		head + Vector2(15.0 * facing, 2.0) * s,
		head + Vector2(8.0 * facing, 4.0) * s,
	]), Color("c98b5a"))
	ci.draw_circle(head + Vector2(3.0 * facing, -2.0) * s, 1.8 * s, Game.INK)
	ci.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-20.0 * facing, -2.0) * s,
		pos + Vector2(-38.0 * facing, -8.0) * s,
		pos + Vector2(-36.0 * facing, 6.0) * s,
	]), shade)
	var tip := pos + Vector2(-14.0 * facing, -30.0 * flap - 4.0) * s
	ci.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-8.0 * facing, -4.0) * s,
		pos + Vector2(10.0 * facing, -4.0) * s,
		tip,
	]), shade)


## Palmier stylisé, silhouette d'une seule couleur.
static func palm(ci: CanvasItem, base: Vector2, h: float, color: Color, sway := 0.0) -> void:
	var top := base + Vector2(sway * 6.0, -h)
	ci.draw_line(base, top, color, h * 0.06)
	for i in 6:
		var ang := -PI * 0.5 + (i - 2.5) * 0.55 + sway * 0.05
		var mid := top + Vector2(cos(ang), sin(ang)) * h * 0.25
		var end := top + Vector2(cos(ang) * h * 0.45, sin(ang) * h * 0.32 + h * 0.16)
		ci.draw_polyline(PackedVector2Array([top, mid, end]), color, h * 0.035, true)


## Motif géométrique (étoiles à 8 branches) sur une zone.
static func star_pattern(ci: CanvasItem, area: Rect2, tile := 64.0, color := Color(0.79, 0.64, 0.29, 0.25)) -> void:
	var y := area.position.y
	while y < area.end.y:
		var x := area.position.x
		while x < area.end.x:
			var c := Vector2(x + tile * 0.5, y + tile * 0.5)
			var r := tile * 0.25
			for k in 2:
				var pts := PackedVector2Array()
				for j in 5:
					var a := PI * 0.25 * k + PI * 0.5 * j + PI * 0.25
					pts.append(c + Vector2(cos(a), sin(a)) * r * 1.414)
				ci.draw_polyline(pts, color, 1.5, true)
			x += tile
		y += tile


## Croissant de lune.
static func crescent(ci: CanvasItem, c: Vector2, r: float, color: Color, bg: Color) -> void:
	ci.draw_circle(c, r, color)
	ci.draw_circle(c + Vector2(r * 0.42, -r * 0.2), r * 0.86, bg)
