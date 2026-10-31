extends CanvasLayer
## Transitions entre scènes : la lumière se referme en forme d'étoile à 8 branches,
## un intertitre peut s'afficher (« Douze ans plus tard… »), puis la scène suivante s'ouvre.

var _rect: ColorRect
var _mat: ShaderMaterial
var _caption: Label
var busy := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://shaders/iris.gdshader")
	_mat.set_shader_parameter("progress", 0.0)
	_rect.material = _mat
	add_child(_rect)

	_caption = Label.new()
	_caption.set_anchors_preset(Control.PRESET_FULL_RECT)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.add_theme_font_override("font", Game.font_title)
	_caption.add_theme_font_size_override("font_size", 52)
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.modulate.a = 0.0
	add_child(_caption)


func _set_progress(p: float) -> void:
	_mat.set_shader_parameter("progress", p)


## Change de scène avec la transition « lanterne ».
func go(path: String, color: Color = Game.NIGHT_DEEP, caption := "", center := Vector2(0.5, 0.5)) -> void:
	if busy:
		return
	busy = true
	Audio.stop_speech()
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var size := get_viewport().get_visible_rect().size
	_mat.set_shader_parameter("aspect", size.x / size.y)
	_mat.set_shader_parameter("tint", color)
	_mat.set_shader_parameter("center", center)
	_caption.add_theme_color_override("font_color", Game.INK if color.get_luminance() > 0.5 else Game.SAND)

	var tw := create_tween()
	tw.tween_method(_set_progress, 0.0, 1.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished

	get_tree().change_scene_to_file(path)

	if caption != "":
		_caption.text = caption
		var tc := create_tween()
		tc.tween_property(_caption, "modulate:a", 1.0, 0.7)
		tc.tween_interval(1.8)
		tc.tween_property(_caption, "modulate:a", 0.0, 0.6)
		await tc.finished
	else:
		await get_tree().create_timer(0.2).timeout

	_mat.set_shader_parameter("center", Vector2(0.5, 0.5))
	var tw2 := create_tween()
	tw2.tween_method(_set_progress, 1.0, 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw2.finished
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busy = false
