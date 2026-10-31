// Transition « lanterne » : un cercle à bord étoilé (8 branches) qui se ferme puis s'ouvre.
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 center = vec2(0.5, 0.5);
uniform vec4 tint : source_color = vec4(0.043, 0.082, 0.141, 1.0);
uniform float aspect = 0.5625;

void fragment() {
	vec2 uv = UV - center;
	uv.x *= aspect;
	float d = length(uv);
	float ang = atan(uv.y, uv.x);
	float r = (1.0 - progress) * 1.25;
	float star = 0.035 * cos(ang * 8.0) * (1.0 - progress);
	float a = smoothstep(r + star - 0.015, r + star, d);
	COLOR = vec4(tint.rgb, tint.a * a);
}
