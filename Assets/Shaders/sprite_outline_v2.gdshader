shader_type canvas_item;
render_mode unshaded;

uniform vec4 line_color : source_color = vec4(1.0);
uniform float line_thickness : hint_range(0,10) = 1.0;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_nearest_mipmap;

uniform bool use_canvas_group = false;

const vec2 OFFSETS[8] = {
	vec2 (-1, -1), vec2(-1, 0), vec2(-1, 1), vec2(0, -1), vec2(0, 1), vec2(1, -1), vec2(1, 0), vec2(1, 1)
};

void fragment() {
	vec4 base = texture(TEXTURE, UV);

	float outline = 0.0;
	vec2 pixel = TEXTURE_PIXEL_SIZE * line_thickness;

	for (int i = 0; i < OFFSETS.length(); i++) {
		outline += texture(TEXTURE, UV + OFFSETS[i] * pixel).a;
	}

	outline = clamp(outline, 0.0, 1.0);

	float edge = max(outline - base.a, 0.0);
	COLOR = mix(base, line_color, edge);
}
