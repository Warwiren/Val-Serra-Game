// P3 — calque de débogage « couches / collisions / niveaux » (au-dessus du décor).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled, blend_mix;
uniform vec4 color : source_color = vec4(0.2, 0.9, 0.3, 0.35);
void fragment() { ALBEDO = color.rgb; ALPHA = color.a; }
