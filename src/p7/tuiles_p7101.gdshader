// P7.10.1 — Tuiles canal de la forge (refonte D) : texture du toit Quaternius, terre cuite désaturée (même teinte que C+),
// variations lentes en coordonnées MONDE (plaques plus claires / plus sombres, tuiles délavées) pour casser la répétition
// de la texture, suie autour de la souche de cheminée. Opaque.
shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform vec3 uv_echelle = vec3(1.0);
uniform vec3 uv_decalage = vec3(0.0);
uniform vec3 teinte = vec3(0.84, 1.0, 1.06);
uniform float relief = 0.6;
uniform float saturation = 0.82;   // terre cuite moins vive que la tuile d'origine (B)
uniform float variation = 0.15;      // amplitude des plaques (luminosité)
uniform float delave = 0.45;         // tuiles délavées (grises) par plaques
uniform vec3 suie_centre = vec3(0.0);
uniform float suie_rayon = 0.0;      // 0 : pas de suie

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
	UV = UV * uv_echelle.xy + uv_decalage.xy;
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 c = texture(albedo_tex, UV).rgb;
	// lichen vert de la texture (motif répété) ramené à un lichen gris-brun discret
	float vert = smoothstep(0.0, 0.08, c.g - c.r * 0.82);
	c = mix(c, vec3(dot(c, vec3(0.4, 0.4, 0.2))) * vec3(0.95, 0.88, 0.80), vert * 0.85);
	c *= teinte;
	c = mix(vec3(dot(c, vec3(0.3, 0.55, 0.15))), c, saturation);
	vec2 p = wpos.xz + vec2(0.0, wpos.y * 0.7);
	float n1 = vbruit(p * 0.42);
	float n2 = vbruit(p * 1.6 + 17.0);
	c *= 1.0 + (n1 - 0.5) * 2.0 * variation + (n2 - 0.5) * variation * 0.7;
	float d = smoothstep(0.58, 0.86, vbruit(p * 0.31 + 5.3));
	float gris = dot(c, vec3(0.3, 0.55, 0.15));
	c = mix(c, vec3(gris) * vec3(1.02, 0.97, 0.92), d * delave);
	if (suie_rayon > 0.0) {
		float ds = length(wpos.xz - suie_centre.xz);
		float s = 1.0 - smoothstep(suie_rayon * 0.35, suie_rayon, ds + (n2 - 0.5) * 0.6);
		c *= 1.0 - s * 0.55;
	}
	ALBEDO = c;
	NORMAL_MAP = texture(normal_tex, UV).rgb;
	NORMAL_MAP_DEPTH = relief;
	ROUGHNESS = 0.9;
	SPECULAR = 0.3;
}
