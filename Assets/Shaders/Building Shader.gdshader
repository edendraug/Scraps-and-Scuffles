shader_type canvas_item;
render_mode unshaded;

/* ==============================
   OUTLINE PARAMETERS
   ============================== */
uniform float outline_width = 1.0;
uniform vec4 outline_color : source_color;

/* ==============================
   DAMAGE PARAMETERS
   ============================== */
uniform sampler2D damage_texture : filter_nearest_mipmap, repeat_enable;

uniform float damage_percent : hint_range(0.0, 1.0) = 0.0;
uniform int total_frames = 12;
uniform vec2 damage_frame_size = vec2(16.0, 16.0);
uniform float damage_scale = 1.0;

uniform bool enable_color_shift = true;
uniform vec4 damage_color : source_color = vec4(1.0, 0.3, 0.3, 1.0);
uniform float color_shift_strength : hint_range(0.0, 1.0) = 0.5;
uniform float blend_strength : hint_range(0.0, 1.0) = 0.8;

void fragment() {
        vec4 base = texture(TEXTURE, UV);
        vec2 texel = TEXTURE_PIXEL_SIZE * outline_width;

        float center_a = base.a;
        float neighbor_max = 0.0;

        // Check 4-directional neighbors
        neighbor_max = max(neighbor_max, texture(TEXTURE, UV + vec2(texel.x, 0.0)).a);
        neighbor_max = max(neighbor_max, texture(TEXTURE, UV - vec2(texel.x, 0.0)).a);
        neighbor_max = max(neighbor_max, texture(TEXTURE, UV + vec2(0.0, texel.y)).a);
        neighbor_max = max(neighbor_max, texture(TEXTURE, UV - vec2(0.0, texel.y)).a);

        bool is_outline = center_a < 0.01 && neighbor_max > 0.01;

        vec4 outlined_color = base;

        if (is_outline) {
                outlined_color = vec4(outline_color.rgb, outline_color.a * neighbor_max);
        }

        /* ==============================
           DAMAGE PASS
           ============================== */

        vec3 result_color = outlined_color.rgb;

        if (outlined_color.a > 0.01 && damage_percent > 0.0 && !is_outline) {
                int current_frame = int(floor(damage_percent * float(total_frames - 1)));
                current_frame = clamp(current_frame, 0, total_frames - 1);

                vec2 sprite_size = vec2(textureSize(TEXTURE, 0));
                vec2 pixel_pos = UV * sprite_size;

                vec2 scaled_frame_size = damage_frame_size * damage_scale;
                vec2 tiled_pixel = mod(pixel_pos, scaled_frame_size);
                vec2 damage_uv_tiled = tiled_pixel / scaled_frame_size;

                float frame_width = 1.0 / float(total_frames);
                vec2 damage_uv = vec2(
                        damage_uv_tiled.x * frame_width + float(current_frame) * frame_width,
                        damage_uv_tiled.y
                );

                vec4 damage = texture(damage_texture, damage_uv);

                if (damage.a > 0.1) {
                        result_color *= mix(vec3(1.0), damage.rgb, damage.a * blend_strength);
                }

                if (enable_color_shift) {
                        float shift_amount = damage_percent * color_shift_strength;
                        result_color = mix(result_color, damage_color.rgb, shift_amount);
                }
        }

        COLOR = vec4(result_color, outlined_color.a);
}