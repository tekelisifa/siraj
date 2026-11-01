class_name Carte
extends Control
## Carte stylisée de l'Arabie et des régions voisines, dessinée en code.
## Les côtes sont simplifiées et les positions approximatives : la carte le dit toujours.
## - `places` : lieux à afficher (clé de LIEUX) ; `highlight` : le lieu mis en valeur.
## - `routes` : trajets [{pts: [[lat, lon], …], progress: 0..1, approx: true}].
## - `zones` : régions approximatives [{nom, lat, lon, r}] (r en degrés).
## - la vue (view_lat, view_lon, view_span) peut être animée avec un Tween.

const LIEUX := {
	"mecque": ["La Mecque", 21.42, 39.83],
	"medine": ["Yathrib (Médine)", 24.47, 39.61],
	"taif": ["Tâ'if", 21.27, 40.42],
	"sanaa": ["Sanaa (Yémen)", 15.37, 44.19],
	"jerusalem": ["Jérusalem", 31.78, 35.23],
	"sham": ["Le Shâm", 33.5, 36.3],
}

## Mers (latitude, longitude), côtes très simplifiées.
const MER_ROUGE := [[29.5, 35.0], [28.0, 35.2], [27.35, 35.7], [26.2, 36.45], [25.05, 37.25], [24.1, 38.05], [22.8, 39.0], [21.5, 39.15], [20.15, 40.25], [19.1, 41.1], [16.9, 42.55], [14.8, 42.95], [13.3, 43.25], [12.6, 43.4], [11.6, 43.15], [13.0, 42.75], [15.6, 39.45], [17.5, 38.6], [19.1, 37.35], [21.0, 37.0], [23.9, 35.8], [25.5, 34.6], [27.25, 33.8], [29.95, 32.55], [27.73, 34.25]]
const OCEAN := [[12.6, 43.4], [12.8, 45.0], [13.4, 47.0], [14.5, 49.1], [15.2, 51.2], [16.6, 53.1], [17.0, 54.1], [18.0, 56.4], [19.0, 57.8], [20.6, 58.9], [22.5, 59.8], [23.2, 62.0], [5.0, 62.0], [5.0, 40.0], [10.4, 45.0], [11.6, 43.15]]
const GOLFE := [[22.5, 59.8], [23.6, 58.6], [24.35, 56.75], [26.4, 56.4], [25.25, 55.3], [24.45, 54.4], [24.1, 52.6], [24.6, 51.6], [25.3, 51.55], [26.15, 51.25], [25.4, 50.8], [26.4, 50.1], [27.0, 49.65], [28.4, 48.5], [29.35, 48.0], [29.95, 48.5], [28.9, 50.8], [27.6, 52.3], [26.6, 54.5], [27.2, 56.3], [25.65, 57.8], [25.3, 61.0], [23.2, 62.0]]
const MEDITERRANEE := [[38.0, 27.0], [38.0, 36.2], [36.6, 36.15], [35.5, 35.8], [34.45, 35.8], [33.9, 35.5], [32.8, 35.0], [32.05, 34.75], [31.5, 34.45], [31.13, 33.8], [31.25, 32.3], [31.2, 29.9], [31.0, 27.0]]

var view_lat := 24.0
var view_lon := 42.0
var view_span := 22.0
var places: Array[String] = []
var highlight := ""
var routes: Array[Dictionary] = []
var zones: Array[Dictionary] = []
var light := 0.0  # lanterne allumée sur le lieu mis en valeur (0..1)
var time := 0.0


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


## Position à l'écran d'un point (latitude, longitude).
func to_xy(lat: float, lon: float) -> Vector2:
	var h := size.y
	var k := h / view_span
	var cosl := cos(deg_to_rad(view_lat))
	return Vector2(size.x * 0.5 + (lon - view_lon) * k * cosl, h * 0.5 - (lat - view_lat) * k)


func place_xy(key: String) -> Vector2:
	var p: Array = LIEUX[key]
	return to_xy(float(p[1]), float(p[2]))


func _poly(coords: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for c in coords:
		out.append(to_xy(float(c[0]), float(c[1])))
	return out


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color("ead6a8"))
	var sea := Color("9fc7c0")
	for m in [MER_ROUGE, OCEAN, GOLFE, MEDITERRANEE]:
		var poly := _poly(m)
		draw_colored_polygon(poly, sea)
		var closed := poly.duplicate()
		closed.append(poly[0])
		draw_polyline(closed, Color("6f9f97"), 2.0, true)
	# Grain du parchemin.
	for i in 18:
		var y := float(i) / 18.0 * size.y
		draw_line(Vector2(0, y), Vector2(size.x, y + 6.0), Color(0.55, 0.42, 0.2, 0.04), 2.0)

	var font := Game.font_body
	for z in zones:
		var c := to_xy(float(z["lat"]), float(z["lon"]))
		var rad := float(z["r"]) * size.y / view_span
		draw_circle(c, rad, Color(Game.GOLD, 0.16))
		_dashed_circle(c, rad, Color(Game.INK, 0.55))
		draw_string(font, c + Vector2(-160, rad + 30), str(z["nom"]), HORIZONTAL_ALIGNMENT_CENTER, 320, 20, Game.INK)

	for rt in routes:
		var pts: Array = rt["pts"]
		var prog := clampf(float(rt.get("progress", 1.0)), 0.0, 1.0)
		var line := _route_points(pts, prog)
		if line.size() >= 2:
			if bool(rt.get("approx", true)):
				_dashed_line(line, Color("8a3b1e"), 4.0)
			else:
				draw_polyline(line, Color("8a3b1e"), 4.0, true)
			draw_circle(line[line.size() - 1], 9.0, Color("8a3b1e"))

	for key in places:
		var p := place_xy(key)
		var main := key == highlight
		if main and light > 0.0:
			var g := light * (0.85 + 0.15 * sin(time * 3.0))
			draw_circle(p, 70.0 * g, Color(Game.FLAME, 0.18 * g))
			draw_circle(p, 36.0 * g, Color(Game.FLAME, 0.35 * g))
		draw_circle(p, 11.0 if main else 8.0, Game.INK)
		draw_circle(p, 6.0 if main else 4.0, Game.GOLD_LIGHT if main else Game.SAND)
		var name := str(LIEUX[key][0])
		draw_string(Game.font_title, p + Vector2(-160, -20), name, HORIZONTAL_ALIGNMENT_CENTER, 320, 28 if main else 23, Game.INK)

	# Rose des vents et avertissement.
	var n := Vector2(size.x - 50.0, 56.0)
	draw_colored_polygon(PackedVector2Array([n + Vector2(0, -26), n + Vector2(9, 8), n + Vector2(-9, 8)]), Game.INK)
	draw_string(Game.font_title, n + Vector2(-20, 34), "N", HORIZONTAL_ALIGNMENT_CENTER, 40, 24, Game.INK)
	draw_string(font, Vector2(16, size.y - 14), "Carte stylisée · positions approximatives", HORIZONTAL_ALIGNMENT_LEFT, size.x - 32, 18, Color(Game.INK, 0.75))
	draw_rect(r, Game.GOLD, false, 4.0)


func _route_points(pts: Array, prog: float) -> PackedVector2Array:
	var xy := PackedVector2Array()
	for c in pts:
		xy.append(to_xy(float(c[0]), float(c[1])))
	if xy.size() < 2:
		return xy
	var total := 0.0
	for i in xy.size() - 1:
		total += xy[i].distance_to(xy[i + 1])
	var want := total * prog
	var out := PackedVector2Array([xy[0]])
	for i in xy.size() - 1:
		var d := xy[i].distance_to(xy[i + 1])
		if want <= d:
			out.append(xy[i].lerp(xy[i + 1], want / maxf(d, 0.001)))
			return out
		want -= d
		out.append(xy[i + 1])
	return out


func _dashed_line(line: PackedVector2Array, col: Color, w: float) -> void:
	for i in line.size() - 1:
		var a := line[i]
		var b := line[i + 1]
		var d := a.distance_to(b)
		var t := 0.0
		while t < d:
			var t2 := minf(t + 14.0, d)
			draw_line(a.lerp(b, t / d), a.lerp(b, t2 / d), col, w, true)
			t += 24.0


func _dashed_circle(c: Vector2, rad: float, col: Color) -> void:
	var n := 28
	for i in n:
		if i % 2 == 0:
			draw_arc(c, rad, TAU * i / n, TAU * (i + 1) / n, 4, col, 2.0, true)
