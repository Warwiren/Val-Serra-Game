// P7.8 — EAU de la fontaine de la grande place (lot 1). OPAQUE (aucune transparence, aucune trame) : couleur de fond et de
// surface, rides animées (relief par dérivées d'écran de deux échantillons défilants de la roche peinte du dépôt), reflet
// spéculaire du ciel, scintillement discret. chute = 1 : filets d'eau qui tombent (bandes qui défilent vers le bas, UV
// du maillage : v le long de la chute).
shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_schlick_ggx;

uniform vec4 profond : source_color = vec4(0.08, 0.20, 0.23, 1.0);
uniform vec4 clair : source_color = vec4(0.30, 0.50, 0.52, 1.0);
uniform sampler2D grain : source_color, repeat_enable, filter_linear_mipmap;
uniform float rides = 1.0;
uniform float vitesse = 1.0;
uniform float chute = 0.0;

varying vec3 wpos;

float hachage(vec2 q) {
	return fract(sin(dot(q, vec2(127.1, 311.7))) * 43758.5453);
}

float vbruit(vec2 q) {
	vec2 i = floor(q);
	vec2 f = fract(q);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hachage(i), hachage(i + vec2(1.0, 0.0)), u.x), mix(hachage(i + vec2(0.0, 1.0)), hachage(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float t = TIME * vitesse;
	if (chute > 0.5) {
		float b = texture(grain, vec2(UV.x * 0.6, UV.y * 0.35 - t * 0.9)).r;
		float s = smoothstep(0.45, 0.75, b);
		ALBEDO = mix(clair.rgb, vec3(0.86, 0.92, 0.92), s * 0.7);
		EMISSION = vec3(0.10, 0.13, 0.13) * s;
		ROUGHNESS = 0.25;
		SPECULAR = 0.6;
	} else {
		vec2 p = wpos.xz;
		// rides LARGES et douces : bruit de valeur procédural lissé (aucune texture : pas de grain à distance)
		float h1 = vbruit(p * 1.1 + vec2(t * 0.35, t * 0.22));
		float h2 = vbruit(p * 1.9 - vec2(t * 0.28, -t * 0.4));
		float h = h1 * 0.6 + h2 * 0.4;
		float e = 0.12;
		float hx = vbruit((p + vec2(e, 0.0)) * 1.1 + vec2(t * 0.35, t * 0.22)) * 0.6 + vbruit((p + vec2(e, 0.0)) * 1.9 - vec2(t * 0.28, -t * 0.4)) * 0.4;
		float hz = vbruit((p + vec2(0.0, e)) * 1.1 + vec2(t * 0.35, t * 0.22)) * 0.6 + vbruit((p + vec2(0.0, e)) * 1.9 - vec2(t * 0.28, -t * 0.4)) * 0.4;
		vec3 n = normalize(vec3((h - hx) * 1.6 * rides, 1.0, (h - hz) * 1.6 * rides));
		NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
		ALBEDO = mix(profond.rgb, clair.rgb, smoothstep(0.3, 0.7, h) * 0.45 + 0.3);
		float eclat = smoothstep(0.72, 0.8, h);
		EMISSION = vec3(0.55, 0.62, 0.6) * eclat * 0.06;
		ROUGHNESS = 0.3;
		SPECULAR = 0.3;
	}
}
