// P4 — halo additif (lanternes, fenêtres) : léger scintillement.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform sampler2D tex : source_color, filter_linear;
uniform vec4 color : source_color = vec4(1.0, 0.72, 0.36, 1.0);
uniform float strength = 0.5;
uniform float phase = 0.0;
void fragment() {
	float f = 0.86 + 0.09 * sin(TIME * 7.3 + phase) + 0.05 * sin(TIME * 13.1 + phase * 2.1);
	ALBEDO = color.rgb * f;
	ALPHA = texture(tex, UV).a * strength * f;
}
