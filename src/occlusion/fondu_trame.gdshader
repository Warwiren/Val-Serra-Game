shader_type spatial;
// P4.9 — fondu tramé d'un obstacle qui masque un personnage. Reproduit un StandardMaterial3D simple (texture, couleur,
// couleurs de sommets, carte de normales, découpe alpha) et retire une part des pixels selon une trame de Bayer 4×4,
// à l'échelle du pixel d'écran (rendu net, sans tri de transparence). `opacite` est réglée par instance.
render_mode cull_disabled, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_tex = true;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform bool use_vcol = false;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform bool use_normal = false;
uniform float normal_scale = 1.0;
uniform float roughness = 1.0;
uniform float metallic = 0.0;
uniform float specular = 0.5;
uniform bool use_scissor = true;
uniform float scissor = 0.5;
instance uniform float opacite = 1.0;

const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

void fragment() {
	vec4 c = albedo_color;
	if (use_tex) {
		c *= texture(albedo_tex, UV);
	}
	if (use_vcol) {
		c *= COLOR;
	}
	if (use_scissor && c.a < scissor) {
		discard;
	}
	ivec2 p = ivec2(FRAGCOORD.xy) % 4;
	if (opacite < (BAYER[p.y * 4 + p.x] + 0.5) / 16.0) {
		discard;
	}
	ALBEDO = c.rgb;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	SPECULAR = specular;
	if (use_normal) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
		NORMAL_MAP_DEPTH = normal_scale;
	}
}
