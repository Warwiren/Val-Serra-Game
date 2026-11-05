// États visuels d'une partie de monstre (calque pixel art) : flash d'impact, endommagé, glande éteinte.
shader_type canvas_item;


uniform float flash = 0.0;
uniform float damaged = 0.0;   // 1 = endommagé : assombri, fissures rougeoyantes qui pulsent
uniform float dead = 0.0;      // 1 = glande éteinte : désaturée et sombre
uniform float time = 0.0;

varying vec4 vcol;

void vertex() {
	vcol = COLOR;
}

float hash(vec2 p) {
	return fract(sin(dot(floor(p), vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 px = UV / TEXTURE_PIXEL_SIZE;          // coordonnées en pixels natifs (fissures alignées sur la grille)
	if (damaged > 0.5) {
		float crack = step(0.93, hash(px * vec2(0.5, 1.0)));
		c.rgb *= 0.78;
		c.rgb = mix(c.rgb, vec3(1.0, 0.35, 0.3), crack * (0.55 + 0.35 * sin(time * 6.0)));
	}
	if (dead > 0.5) {
		float g = dot(c.rgb, vec3(0.3, 0.59, 0.11));
		c.rgb = vec3(g) * vec3(0.35, 0.4, 0.5);
	}
	c.rgb = mix(c.rgb, vec3(1.0), flash);
	COLOR = c * vcol;
}
