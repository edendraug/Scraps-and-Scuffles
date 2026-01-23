shader_type canvas_item;

uniform float outline_width = 2.0;
uniform vec4 outline_color : source_color;

uniform sampler2D screen_texture: hint_screen_texture, filter_nearest, repeat_disable;

void fragment() {
	vec4 col = texture(screen_texture, SCREEN_UV);
	vec2 ps = SCREEN_PIXEL_SIZE;
	float a;
	float maxa = col.a;
	float mina = col.a;

	a = texture(screen_texture, SCREEN_UV + vec2(0.0, -outline_width) * ps).a;
	maxa = max(a, maxa);
	mina = min(a, mina);

	a = texture(screen_texture, SCREEN_UV + vec2(0.0, outline_width) * ps).a;
	maxa = max(a, maxa);
	mina = min(a, mina);

	a = texture(screen_texture, SCREEN_UV + vec2(-outline_width, 0.0) * ps).a;
	maxa = max(a, maxa);
	mina = min(a, mina);

	a = texture(screen_texture, SCREEN_UV + vec2(outline_width, 0.0) * ps).a;
	maxa = max(a, maxa);
	mina = min(a, mina);

	COLOR = mix(col, outline_color, maxa - mina);
}