// P3 — ombre de contact (disque doux) sous les personnages.
shader_type spatial;
render_mode unshaded, depth_draw_never, cull_disabled, blend_mix;
uniform float strength = 0.45;
void fragment() {
	float r = length(UV - vec2(0.5)) * 2.0;
	ALBEDO = vec3(0.0);
	ALPHA = strength * (1.0 - smoothstep(0.55, 1.0, r));
}
