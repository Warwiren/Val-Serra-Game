// P3 — silhouette du personnage visible UNIQUEMENT là où le décor le cache (test de profondeur inversé).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_inverted, blend_mix;
uniform sampler2D tex : source_color, filter_nearest;
uniform vec4 tint : source_color = vec4(0.62, 0.74, 1.0, 0.55);
uniform float flip = 0.0;
void fragment() {
	vec2 uv = vec2(flip > 0.5 ? 1.0 - UV.x : UV.x, UV.y);
	float a = texture(tex, uv).a;
	if (a < 0.5) { discard; }
	ALBEDO = tint.rgb;
	ALPHA = tint.a;
}
