// P4.1 — personnages et monstre : échantillonnage « pixel net ». Chaque texel du pixel-art garde des bords francs
// quel que soit le rapport d'agrandissement (×1,2 à ×2), avec une transition d'un seul pixel d'écran (pas
// d'escalier irrégulier comme en « nearest » à facteur non entier, pas de flou comme en bilinéaire agrandi).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix, shadows_disabled;
uniform sampler2D tex : source_color, filter_linear, repeat_disable;
uniform float flip = 0.0;
uniform vec4 tint : source_color = vec4(1.0);
uniform float sharp = 1.0;          // 0 : bilinéaire simple (comparaison)
void fragment() {
	vec2 uv = vec2(mix(UV.x, 1.0 - UV.x, flip), UV.y);
	vec2 sz = vec2(textureSize(tex, 0));
	vec2 px = uv * sz;
	vec2 fw = max(fwidth(px), vec2(1e-4));
	vec2 seam = floor(px + 0.5);
	vec2 sp = seam + clamp((px - seam) / fw, -0.5, 0.5);
	vec4 t = texture(tex, mix(uv, sp / sz, sharp));
	ALBEDO = t.rgb * tint.rgb;
	ALPHA = t.a;
}
