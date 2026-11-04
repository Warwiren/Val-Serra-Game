// Flou de profondeur + brume atmosphérique pour les calques de décor (variante B).
shader_type canvas_item;

uniform float radius = 1.5;
uniform float fog = 0.0;
uniform vec4 fog_color : source_color = vec4(0.72, 0.78, 0.9, 1.0);
uniform vec4 tint : source_color = vec4(1.0);

void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE * radius;
	vec4 acc = vec4(0.0);
	float w = 0.0;
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			float k = 1.0 / (1.0 + float(x * x + y * y));
			acc += texture(TEXTURE, UV + vec2(float(x), float(y)) * px) * k;
			w += k;
		}
	}
	acc /= w;
	acc.rgb = mix(acc.rgb, fog_color.rgb, fog);
	COLOR = acc * tint;
}
