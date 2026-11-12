// P4 — matériau de surface texturé : UV monde (dessus = plan XZ, faces = triplanaire) ou UV du maillage,
// variation lente contre la répétition, et « trou de visibilité » tramé autour du héros pour les occultants.
shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;
uniform sampler2D tex : source_color, repeat_enable, filter_linear_mipmap;
uniform float tile_m = 4.0;
uniform vec4 tint : source_color = vec4(1.0);
uniform float macro = 0.10;
uniform float uv_mode = 0.0;      // 0 : UV monde ; 1 : UV du maillage
uniform float hole = 0.0;         // 1 : cet objet peut cacher le héros (masquage localisé)
uniform float emit = 0.0;
uniform float antitile = 0.0;    // P4.1 : 1 = deux échantillonnages mélangés par un bruit lent (casse la répétition)
uniform float grid = 0.0;         // compatibilité P3 (non utilisé)
uniform float fade = 1.0;         // compatibilité P3 (non utilisé)
global uniform vec3 p4_hero;
global uniform float p4_hole;
global uniform float p4_persp;
varying vec3 wpos;
varying vec3 wnrm;
float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1.0, 0.0)), f.x), mix(h21(i + vec2(0.0, 1.0)), h21(i + vec2(1.0, 1.0)), f.x), f.y);
}
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec2 uv = UV;
	if (uv_mode < 0.5) {
		if (abs(wnrm.y) > 0.5) { uv = wpos.xz; }
		else if (abs(wnrm.x) > 0.5) { uv = vec2(wpos.z, -wpos.y); }
		else { uv = vec2(wpos.x, -wpos.y); }
		uv /= tile_m;
	}
	vec3 c = texture(tex, uv).rgb;
	vec2 wp = wpos.xz + vec2(wpos.y * 0.7, 0.0);
	if (antitile > 0.5) {
		vec2 uv2 = mat2(vec2(0.8, -0.6), vec2(0.6, 0.8)) * uv * 0.77 + vec2(0.31, 0.17);
		float m = smoothstep(0.32, 0.68, vnoise(wp * 0.19));
		c = mix(c, texture(tex, uv2).rgb, m);
		// plaques plus sèches / plus sombres à grande échelle
		c = mix(c, c * vec3(1.1, 1.05, 0.82), smoothstep(0.55, 0.9, vnoise(wp * 0.09 + 7.3)) * 0.45);
	} else {
		// pierre et pavés : salissures et mousse irrégulières, sans déformer le motif
		c = mix(c, c * vec3(0.82, 0.92, 0.78), smoothstep(0.58, 0.92, vnoise(wp * 0.33 + 3.1)) * 0.5);
	}
	c *= tint.rgb;
	if (abs(wnrm.y) < 0.5 && antitile < 0.5) {
		// maçonnerie : pied des murs assombri (contact avec le sol de la cour ou de la terrasse), haut plus clair
		float ao = smoothstep(0.0, 0.75, wpos.y);
		if (wpos.y > 1.18) { ao = min(ao, smoothstep(1.18, 1.85, wpos.y)); }
		c *= mix(0.62, 1.0, ao) * (0.94 + 0.06 * clamp(wpos.y / 3.0, 0.0, 1.0));
	}
	float n = vnoise(wp * 0.07) * 2.0 - 1.0;
	c *= 1.0 + macro * 1.4 * n;
	ALBEDO = c;
	EMISSION = c * emit;
	ROUGHNESS = 1.0;
	if (hole > 0.5 && p4_hole > 0.01) {
		vec3 hv = (VIEW_MATRIX * vec4(p4_hero, 1.0)).xyz;
		if (VERTEX.z > hv.z + 0.35) {
			// distance mesurée à l'écran (perspective : coordonnées ramenées à la profondeur du héros)
			vec2 dv = p4_persp > 0.5 ? (VERTEX.xy / -VERTEX.z - hv.xy / -hv.z) * -hv.z : VERTEX.xy - hv.xy;
			float d = length(dv * vec2(1.0, 0.8));
			float keep = mix(1.0, smoothstep(0.75, 1.55, d), p4_hole);
			float th = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
			if (keep < th) { discard; }
		}
	}
}
