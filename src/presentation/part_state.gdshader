// États visuels d'une partie de monstre (calque pixel art) : flash d'impact, endommagé, glande éteinte.
shader_type canvas_item;


uniform float flash = 0.0;
uniform float damaged = 0.0;   // 1 = endommagé : assombri, fissures rougeoyantes qui pulsent
uniform float dead = 0.0;      // 1 = glande éteinte : désaturée et sombre
uniform float time = 0.0;
uniform float charge = 0.0;
// Éclairage de scène : positions RÉELLES des lanternes (coordonnées du canevas), mêmes sources que le décor.
// Les bords tournés vers une source proche reçoivent un liseré chaud ; atténuation quadratique avec la distance.
uniform vec2 lights[4];
uniform int light_count = 0;
uniform float light_radius = 600.0;
uniform vec4 light_color : source_color = vec4(1.0, 0.72, 0.42, 1.0);
uniform float light_strength = 0.0;
uniform float flip_x = 1.0;            // -1 si le calque est retourné horizontalement    // glande : charge du Souffle (émission cyan sur les SEULS pixels de la glande)

varying vec4 vcol;
varying vec2 world;

void vertex() {
	vcol = COLOR;
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
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
	float lit = 0.0;
	for (int i = 0; i < light_count; i++) {
		vec2 d = lights[i] - world;
		float fall = clamp(1.0 - length(d) / light_radius, 0.0, 1.0);
		vec2 dir = normalize(d);
		float edge = c.a * (1.0 - texture(TEXTURE, UV + vec2(dir.x * flip_x, dir.y) * TEXTURE_PIXEL_SIZE).a);
		lit += fall * fall * (0.2 + 0.8 * edge);
	}
	c.rgb += light_color.rgb * clamp(lit * light_strength, 0.0, 0.6) * 0.8;
	c.rgb = mix(c.rgb, vec3(0.75, 1.0, 1.0), charge * 0.55);
	c.rgb = mix(c.rgb, vec3(1.0), flash);
	COLOR = c * vcol;
}
