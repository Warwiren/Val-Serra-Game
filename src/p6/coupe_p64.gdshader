// P6.4 — modèle vu EN COUPE (porte fermée dans un mur coupé) : la partie au-dessus du plan de coupe (hauteur monde)
// est retirée ; l'intérieur mis à nu (faces arrière) est rendu dans la teinte sombre de la tranche des murs (poché).
shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 albedo : source_color = vec4(1.0);
uniform float has_tex = 1.0;
uniform vec3 uv1_scale = vec3(1.0);
uniform vec3 uv1_offset = vec3(0.0);
uniform float y_coupe = 0.5;
uniform float miroir = 0.0;        // modèle à échelle négative (vantail en miroir) : faces avant / arrière inversées
uniform vec4 c_coupe : source_color = vec4(0.09, 0.075, 0.07, 1.0);
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	UV = UV * uv1_scale.xy + uv1_offset.xy;
}
void fragment() {
	if (wpos.y > y_coupe) { discard; }
	vec3 c = albedo.rgb;
	if (has_tex > 0.5) { c *= texture(albedo_tex, UV).rgb; }
	bool dos = miroir > 0.5 ? FRONT_FACING : !FRONT_FACING;
	if (dos) { c = c_coupe.rgb; NORMAL = -NORMAL; }
	ALBEDO = c;
	ROUGHNESS = 0.9;
}
