// P3 — matériau de blockout (couleur unie, éclairage Lambert, grille d'1 m facultative, transparence tramée locale).
shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;
uniform vec4 albedo : source_color = vec4(0.6, 0.6, 0.6, 1.0);
uniform float grid = 0.0;
uniform float fade = 1.0;
varying vec3 wpos;
varying vec3 wnrm;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec3 c = albedo.rgb;
	if (grid > 0.5 && wnrm.y > 0.7) {
		vec2 g = abs(fract(wpos.xz + 0.5) - 0.5);
		float l = min(g.x, g.y);
		c *= mix(0.80, 1.0, smoothstep(0.0, 0.025, l));
	}
	ALBEDO = c;
	ROUGHNESS = 1.0;
	ALPHA = fade;
	ALPHA_HASH_SCALE = 1.0;
}
