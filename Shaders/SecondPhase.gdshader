shader_type canvas_item;

uniform float time : hint_range(0, 1000);
uniform vec4 glow_color : source_color = vec4(1.0, 0.1, 0.1, 1.0);
uniform float pulse_speed : hint_range(0.1, 10.0) = 2.0;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	// Pulse effect based on time
	float pulse = abs(sin(time * pulse_speed)) * 0.5 + 0.5;
	
	vec4 final_color = mix(tex_color, glow_color, pulse * tex_color.a);
	COLOR = final_color;
}
