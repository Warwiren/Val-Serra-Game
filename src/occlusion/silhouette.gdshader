shader_type spatial;
// P4.9 — silhouette discrète d'un personnage derrière un tronc ou un rocher. Test de profondeur INVERSÉ : seules les
// parties réellement cachées sont dessinées, jamais par-dessus la partie visible du sprite. Couleur sourde, sans
// émission ni contour lumineux. Face à la caméra (billboard), comme le sprite qu'elle double.
render_mode unshaded, depth_test_inverted, depth_draw_never, cull_disabled, blend_mix, shadows_disabled;

uniform sampler2D tex : source_color, filter_nearest;
uniform vec3 teinte : source_color = vec3(0.30, 0.34, 0.41);   // ardoise sourde : lisible sur pierre et écorce, sans éclat
uniform float alpha = 0.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	vec4 c = texture(tex, UV);
	if (c.a < 0.5 || alpha <= 0.001) {
		discard;
	}
	float lum = dot(c.rgb, vec3(0.3, 0.59, 0.11));
	ALBEDO = teinte * (0.75 + 0.5 * lum);
	ALPHA = alpha;
}
