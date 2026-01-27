shader_type canvas_item;

// Damage texture (horizontal sprite sheet)
uniform sampler2D damage_texture : filter_nearest_mipmap, repeat_enable;

// Damage parameters
uniform float damage_percent : hint_range(0,0, 1.0) = 0.0;
uniform int total_frames = 12;
uniform vec2 damage_frame_size = vec2(16.0, 16.0); // Size of one frame in pixels
uniform float damage_scale = 1.0; // Scale multiplier for damage texture

// Color modulation
uniform bool enable_color_shift = true;
uniform vec4 damage_color : source_color = vec4(1.0, 0.3, 0.3, 1.0); //Red tint
uniform float color_shift_strength : hint_range(0.0, 1.0) = 0.5;

// Blend mode
uniform float blend_strength : hint_range(0.0, 1.0) = 0.8;

void fragment() {
	// Get the base sprite color
	vec4 base_color = texture(TEXTURE, UV);

	// Only apply damage to visible pixels
	if (base_color.a > 0.01) {
		//Calculate which damage frame to use
		int current_frame = int(floor(damage_percent * float(total_frames -1)));
		current_frame = clamp(current_frame, 0, total_frames - 1);

		// Get sprite size in pixels
		vec2 sprite_size = vec2(textureSize(TEXTURE, 0));

		// Convert UV to pixel coordinates
		vec2 pixel_pos = UV * sprite_size;

		// Tile based on damage frame size (16x16)
		vec2 scaled_frame_size = damage_frame_size * damage_scale;
		vec2 tiled_pixel = mod(pixel_pos, scaled_frame_size);

		// Convert back to UV space for the damage texture
		vec2 damage_uv_tiled = tiled_pixel / scaled_frame_size;

		// Offset to correct frame in the horizontal sprite sheet
		float frame_width = 1.0 / float(total_frames);
		vec2 damage_uv = vec2(
			damage_uv_tiled.x * frame_width + (float(current_frame) * frame_width), // X: within the current frame
			damage_uv_tiled.y // Y: normal tiling
		);

		vec4 damage = texture(damage_texture, damage_uv);

		// Blend damage overlay with base sprite
		vec3 result_color = base_color.rgb;

		// Multiply blend the damage texture (darkens where damage is)
		if (damage.a > 0.1) {
			result_color = result_color * mix(vec3(1.0), damage.rgb, damage.a * blend_strength);
		}

		//Apply color shift based on damage
		if (enable_color_shift && damage_percent > 0.0) {
			float shift_amount = damage_percent * color_shift_strength;
			result_color = mix(result_color, damage_color.rgb, shift_amount);
		}

		COLOR = vec4(result_color, base_color.a);
	} else {
		COLOR = base_color;
	}
}