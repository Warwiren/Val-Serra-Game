// P6.4 — SILHOUETTE d'une porte fermée au-dessus du plan de coupe : la partie retirée reste lisible en transparence
// (taille réelle de la porte, Aren visible au travers). Fondu doux vers le haut ; aucune ombre portée.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, diffuse_lambert, specular_disabled, shadows_disabled;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 albedo : source_color = vec4(1.0);
uniform float has_tex = 1.0;
uniform vec3 uv1_scale = vec3(1.0);
uniform vec3 uv1_offset = vec3(0.0);
uniform float y_coupe = 0.5;
uniform float opacite = 0.32;
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	UV = UV * uv1_scale.xy + uv1_offset.xy;
}
void fragment() {
	if (wpos.y < y_coupe) { discard; }
	vec3 c = albedo.rgb;
	if (has_tex > 0.5) { c *= texture(albedo_tex, UV).rgb; }
	ALBEDO = mix(c, vec3(dot(c, vec3(0.3, 0.55, 0.15))), 0.35);
	ROUGHNESS = 0.9;
	ALPHA = opacite * (1.0 - 0.35 * smoothstep(0.0, 2.0, wpos.y - y_coupe));
}
