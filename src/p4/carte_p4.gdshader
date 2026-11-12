// P4 — carte illustrée verticale (végétation, accessoires) : découpe alpha en passe opaque (écrit la profondeur :
// les personnages passent devant ou derrière), balancement léger du haut de l'image, trou de visibilité tramé.
shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(1.0);
uniform float sway = 0.0;         // amplitude (m) au sommet
uniform float phase = 0.0;
uniform float hole = 0.0;
uniform float emit = 0.0;         // lueur des pixels chauds (lanternes)
uniform float cut = 0.5;
global uniform vec3 p4_hero;
global uniform float p4_hole;
void vertex() {
	float k = (1.0 - UV.y);
	VERTEX.x += sway * k * k * (sin(TIME * 1.15 + phase) + 0.35 * sin(TIME * 2.7 + phase * 1.7));
}
void fragment() {
	vec4 t = texture(tex, UV);
	if (t.a < cut) { discard; }
	ALBEDO = t.rgb * tint.rgb;
	NORMAL = normalize((VIEW_MATRIX * vec4(0.15, 1.0, 0.4, 0.0)).xyz);
	float warm = smoothstep(0.62, 0.9, t.r) * smoothstep(0.35, 0.6, t.g) * step(t.b, t.r * 0.8);
	EMISSION = t.rgb * emit * warm;
	ROUGHNESS = 1.0;
	if (hole > 0.5 && p4_hole > 0.01) {
		vec3 hv = (VIEW_MATRIX * vec4(p4_hero, 1.0)).xyz;
		if (VERTEX.z > hv.z + 0.35) {
			float d = length((VERTEX.xy - hv.xy) * vec2(1.0, 0.8));
			float keep = mix(1.0, smoothstep(0.75, 1.55, d), p4_hole);
			float th = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
			if (keep < th) { discard; }
		}
	}
}
