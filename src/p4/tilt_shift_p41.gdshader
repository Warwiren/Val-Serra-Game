// P4.1 — flou de distance « miniature » (tilt-shift) des variantes caméra en perspective : le haut de l'écran (le
// lointain) et l'extrême bas sont flous, la bande du jeu reste nette. Écrit en canvas_item pour fonctionner aussi
// en rendu Compatibility (la profondeur de champ de Godot n'y est pas disponible).
shader_type canvas_item;
uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform float top_end = 0.30;      // flou maximal en haut, nul à partir de cette hauteur d'écran
uniform float bottom_start = 0.9;
uniform float radius_px = 3.2;
const vec2 TAPS[12] = vec2[](vec2(-0.326, -0.406), vec2(-0.840, -0.074), vec2(-0.696, 0.457), vec2(-0.203, 0.621),
	vec2(0.962, -0.195), vec2(0.473, -0.480), vec2(0.519, 0.767), vec2(0.185, -0.893), vec2(0.507, 0.064),
	vec2(0.896, 0.412), vec2(-0.322, -0.933), vec2(-0.792, -0.598));
void fragment() {
	float y = SCREEN_UV.y;
	float b = max(smoothstep(top_end, 0.0, y), smoothstep(bottom_start, 1.0, y) * 0.6);
	vec4 c = texture(screen, SCREEN_UV);
	if (b > 0.01) {
		vec4 acc = c;
		for (int i = 0; i < 12; i++) {
			acc += texture(screen, SCREEN_UV + TAPS[i] * radius_px * b * SCREEN_PIXEL_SIZE * 2.0);
		}
		c = acc / 13.0;
	}
	COLOR = vec4(c.rgb, 1.0);
}
