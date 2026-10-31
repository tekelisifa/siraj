class_name UI
extends RefCounted
## Petites fabriques d'éléments d'interface, pour garder les scènes lisibles.


static func label(text: String, size := 30, color := Color("f3e6cc"), font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if font != null:
		l.add_theme_font_override("font", font)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func button(text: String, primary := true) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 100)
	b.focus_mode = Control.FOCUS_NONE
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if not primary:
		b.theme_type_variation = &"SecondaryButton"
	b.pressed.connect(func() -> void: Input.vibrate_handheld(15))
	return b


static func vbox(separation := 16) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", separation)
	return v


## Un calque d'interface plein écran, au-dessus du décor.
static func layer(parent: Node) -> Control:
	var cl := CanvasLayer.new()
	parent.add_child(cl)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(root)
	return root


## Place un contrôle en bas de l'écran, avec des marges ; il grandit vers le haut.
static func dock_bottom(c: Control, margin := 32, bottom := 48) -> void:
	c.anchor_left = 0.0
	c.anchor_right = 1.0
	c.anchor_top = 1.0
	c.anchor_bottom = 1.0
	c.offset_left = margin
	c.offset_right = -margin
	c.offset_top = -bottom
	c.offset_bottom = -bottom
	c.grow_vertical = Control.GROW_DIRECTION_BEGIN


## Place un contrôle en haut de l'écran ; il grandit vers le bas.
static func dock_top(c: Control, margin := 32, top := 56) -> void:
	c.anchor_left = 0.0
	c.anchor_right = 1.0
	c.anchor_top = 0.0
	c.anchor_bottom = 0.0
	c.offset_left = margin
	c.offset_right = -margin
	c.offset_top = top
	c.offset_bottom = top
	c.grow_vertical = Control.GROW_DIRECTION_END


static func fade_in(c: CanvasItem, duration := 0.6, delay := 0.0) -> void:
	c.modulate.a = 0.0
	var tw := c.create_tween()
	tw.tween_interval(delay)
	tw.tween_property(c, "modulate:a", 1.0, duration)


## Texte centré dessiné directement dans un _draw().
static func draw_text(ci: CanvasItem, font: Font, center_x: float, baseline_y: float, text: String, size: int, color: Color) -> void:
	ci.draw_string(font, Vector2(center_x - 500.0, baseline_y), text, HORIZONTAL_ALIGNMENT_CENTER, 1000.0, size, color)
