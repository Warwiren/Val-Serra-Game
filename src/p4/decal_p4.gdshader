// P4 — calque de transition posé sur le sol (TRS-01 herbe sur terre, BER-01 berge sur eau) : l'alpha de l'image est
// rendu par tramage en passe opaque, pour ne jamais passer devant les personnages (qui n'écrivent pas la profondeur).
shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
uniform sampler2D tex : source_color, repeat_enable, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(1.0);
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec4 t = texture(tex, UV);
	// P4.1 : seuil tiré par cellule de 5 cm au sol (bord irrégulier « en grains ») au lieu d'une trame d'écran régulière
	vec2 cell = floor(wpos.xz * 20.0);
	float th = fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
	if (t.a < 0.04 + th * 0.92) { discard; }
	ALBEDO = t.rgb * tint.rgb;
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	ROUGHNESS = 1.0;
}
