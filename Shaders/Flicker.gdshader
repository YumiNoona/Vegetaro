shader_type canvas_item;

uniform float flicker_speed = 40.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float flicker = step(0.5, abs(sin(TIME * flicker_speed)));
    COLOR = vec4(tex.rgb, tex.a * flicker);
}
