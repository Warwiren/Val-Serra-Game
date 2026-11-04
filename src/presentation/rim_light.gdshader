// Liseré de lumière (contre-jour lunaire) + flash d'impact, pour les calques de personnages et monstres.
// Le liseré apparaît sur les bords du calque tournés vers la lumière.
shader_type canvas_item;

uniform vec4 rim_color : source_color = vec4(0.62, 0.86, 1.0, 1.0);
uniform vec2 light_dir = vec2(0.75, -0.65);
uniform float width = 3.0;
uniform float strength = 0.85;
uniform float flash = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

varying vec4 vcol;

void vertex() {
	vcol = COLOR;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 off = normalize(light_dir) * width * TEXTURE_PIXEL_SIZE;
	float a2 = texture(TEXTURE, UV + off).a;
	float rim = c.a * (1.0 - a2);
	c.rgb = mix(c.rgb, rim_color.rgb, clamp(rim * strength, 0.0, 1.0));
	c.rgb = mix(c.rgb, flash_color.rgb, flash);
	COLOR = c * vcol;
}
