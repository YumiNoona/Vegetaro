shader_type canvas_item;

uniform float health_percent : hint_range(0.0, 1.0) = 1.0;
uniform float time_offset : hint_range(0.0, 10.0) = 0.0;
uniform vec4 fill_color : source_color = vec4(0.8, 0.2, 0.2, 1.0);
uniform vec4 glow_color : source_color = vec4(1.0, 0.3, 0.3, 1.0);

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	// Animated glow effect
	float glow = abs(sin((TIME + time_offset) * 3.0)) * 0.3 + 0.7;
	
	// Pulsing effect when health is low
	float pulse = 1.0;
	if (health_percent < 0.3) {
		pulse = abs(sin((TIME + time_offset) * 5.0)) * 0.2 + 0.8;
	}
	
	// Mix colors with glow
	vec4 final_color = mix(fill_color, glow_color, (1.0 - glow) * 0.3);
	final_color.rgb *= pulse;
	
	COLOR = vec4(final_color.rgb, tex_color.a * final_color.a);
}

