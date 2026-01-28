shader_type canvas_item;

/* ==============================
   OUTLINE PARAMETERS
   ============================== */
uniform float outline_width = 2.0;
uniform vec4 outline_color : source_color;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;

/* ==============================
   DAMAGE PARAMETERS
   ============================== */

// Damage texture (horizontal sprite sheet)
uniform sampler2D damage_texture : filter_nearest_mipmap, repeat_enable;

// Damage control
uniform float damage_percent : hint_range(0.0, 1.0) = 0.0;
uniform int total_frames = 12;
uniform vec2 damage_frame_size = vec2(16.0, 16.0);
uniform float damage_scale = 1.0;

// Color modulation
uniform bool enable_color_shift = true;
uniform vec4 damage_color : source_color = vec4(1.0, 0.3, 0.3, 1.0);
uniform float color_shift_strength : hint_range(0.0, 1.0) = 0.5;

// Blend
uniform float blend_strength : hint_range(0.0, 1.0) = 0.8;

void fragment() {
        /* ==============================
           OUTLINE PASS (SCREEN SPACE)
           ============================== */

        vec4 col = texture(screen_texture, SCREEN_UV);
        vec2 ps = SCREEN_PIXEL_SIZE;

        float maxa = col.a;
        float mina = col.a;

        float a;

        a = texture(screen_texture, SCREEN_UV + vec2(0.0, -outline_width) * ps).a;
        maxa = max(maxa, a);
        mina = min(mina, a);

        a = texture(screen_texture, SCREEN_UV + vec2(0.0, outline_width) * ps).a;
        maxa = max(maxa, a);
        mina = min(mina, a);

        a = texture(screen_texture, SCREEN_UV + vec2(-outline_width, 0.0) * ps).a;
        maxa = max(maxa, a);
        mina = min(mina, a);

        a = texture(screen_texture, SCREEN_UV + vec2(outline_width, 0.0) * ps).a;
        maxa = max(maxa, a);
        mina = min(mina, a);

        // Final outlined color
        vec4 outlined_color = mix(col, outline_color, maxa - mina);

        /* ==============================
           DAMAGE PASS (OBJECT SPACE)
           ============================== */

        vec4 base_color = outlined_color;

        if (base_color.a > 0.01 && damage_percent > 0.0) {

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

                vec3 result_color = base_color.rgb;

                if (damage.a > 0.1) {
                        result_color *= mix(vec3(1.0), damage.rgb, damage.a * blend_strength);
                }

                if (enable_color_shift) {
                        float shift_amount = damage_percent * color_shift_strength;
                        result_color = mix(result_color, damage_color.rgb, shift_amount);
                }

                COLOR = vec4(result_color, base_color.a);
        } else {
                COLOR = base_color;
        }
}