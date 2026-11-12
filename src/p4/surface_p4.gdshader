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
uniform float grid = 0.0;         // compatibilité P3 (non utilisé)
uniform float fade = 1.0;         // compatibilité P3 (non utilisé)
global uniform vec3 p4_hero;
global uniform float p4_hole;
varying vec3 wpos;
varying vec3 wnrm;
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
	vec3 c = texture(tex, uv).rgb * tint.rgb;
	float n = sin(wpos.x * 0.37 + sin(wpos.z * 0.23) * 2.0) * sin(wpos.z * 0.31 + 1.7 + wpos.y * 0.9);
	c *= 1.0 + macro * n;
	ALBEDO = c;
	EMISSION = c * emit;
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
