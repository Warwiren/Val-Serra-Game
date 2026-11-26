// P7.6 — ENDUIT À LA CHAUX des étages (tranche architecturale de la ville, PILOTE NON VALIDÉ).
// Teinte de base + marbrures à basse fréquence (luminance de la roche peinte du dépôt, art/p4/mat/roche.png, avec mipmaps :
// aucune répétition visible), salissure au pied et sous la corniche, coulures sous les appuis de fenêtre (bandes
// verticales tirées de la même texture). UV monde (faces planes alignées) : un mètre de façade = un mètre d'enduit.
// « Trou » tramé autour du héros identique à src/p6/maconnerie_p64.gdshader (occlusion validée, non modifiée).
shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;

uniform vec4 couleur : source_color = vec4(0.86, 0.80, 0.68, 1.0);
uniform sampler2D grain : source_color, repeat_enable, filter_linear_mipmap;
uniform float marbrure = 0.16;      // amplitude des marbrures
uniform float base_y = 0.0;         // pied de l'enduit (m)
uniform float haut_y = 6.0;         // sommet de l'enduit (corniche)
uniform float salissure = 0.22;     // assombrissement au pied et sous la corniche
uniform float coulures = 0.12;
uniform float valeur = 0.82;        // étalonné sur la maçonnerie du Colisée (même éclairage)
uniform float hole = 0.0;
global uniform vec3 p4_hero;
global uniform float p4_hole;
global uniform float p4_persp;

varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 p = abs(wnrm.x) > 0.5 ? vec2(wpos.z, wpos.y) : vec2(wpos.x, wpos.y);
	if (abs(wnrm.y) > 0.5) { p = wpos.xz; }
	float g1 = dot(texture(grain, p / 3.1).rgb, vec3(0.333));
	float g2 = dot(texture(grain, p / 0.9 + vec2(0.37, 0.11)).rgb, vec3(0.333));
	float m = (g1 - 0.5) * 1.0 + (g2 - 0.5) * 0.45;
	vec3 c = couleur.rgb * (1.0 + marbrure * m);
	// salissure : pied de l'enduit (remontées), sous la corniche (eau)
	float pied = 1.0 - smoothstep(0.0, 0.9, wpos.y - base_y);
	float tete = 1.0 - smoothstep(0.0, 0.6, haut_y - wpos.y);
	c *= 1.0 - salissure * (0.6 * pied + 0.5 * tete);
	// coulures : bandes verticales irrégulières
	float cv = texture(grain, vec2(p.x / 0.7, p.y / 9.0)).r;
	c *= 1.0 - coulures * smoothstep(0.55, 0.8, cv) * (0.4 + 0.6 * tete);
	ALBEDO = c * valeur;
	ROUGHNESS = 1.0;
	if (hole > 0.5 && p4_hole > 0.01) {
		vec3 hv = (VIEW_MATRIX * vec4(p4_hero, 1.0)).xyz;
		if (VERTEX.z > hv.z + 0.35) {
			vec2 dv = p4_persp > 0.5 ? (VERTEX.xy / -VERTEX.z - hv.xy / -hv.z) * -hv.z : VERTEX.xy - hv.xy;
			float dd = length(dv * vec2(1.0, 0.8));
			float keep = mix(1.0, smoothstep(0.75, 1.55, dd), p4_hole);
			float th = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
			if (keep < th) { discard; }
		}
	}
}
