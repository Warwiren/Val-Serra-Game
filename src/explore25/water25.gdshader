// P3 — eau de blockout animable (commutateur « anim ») : ondulation de couleur, sans texture.
shader_type spatial;
render_mode cull_back, diffuse_lambert;
uniform vec4 albedo : source_color = vec4(0.2, 0.4, 0.58, 1.0);
uniform float anim = 1.0;
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float t = TIME * anim;
	float w = sin(wpos.z * 2.1 + t * 1.7 + sin(wpos.x * 1.3) * 1.5) * 0.5 + 0.5;
	float w2 = sin(wpos.z * 5.3 - t * 2.3 + wpos.x * 0.7) * 0.5 + 0.5;
	ALBEDO = albedo.rgb * (0.86 + 0.14 * w) + vec3(0.05) * smoothstep(0.85, 1.0, w2);
	ROUGHNESS = 0.35;
	SPECULAR = 0.4;
}
