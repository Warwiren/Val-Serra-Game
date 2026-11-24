// P7.1 — MATÉRIAU DE BLOCKOUT (prototype de circulation de la ville, NON définitif).
// Couleur unie par fonction + repères de mesure : quadrillage d'1 m discret (sols), lignes d'étage tous les 3 m et
// baies schématiques (façades), pour juger proportions et distances. Aucune texture, aucun habillage.
// Les lignes sont filtrées (fwidth) : elles s'effacent à distance au lieu de scintiller.
// « Trou » tramé autour du héros identique à src/p6/maconnerie_p64.gdshader (occlusion validée de la forêt).
shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;

uniform vec4 couleur : source_color = vec4(0.7, 0.68, 0.64, 1.0);
uniform float grille = 1.0;        // 1 : quadrillage métrique (sols, dessus)
uniform float facade = 0.0;        // 1 : lignes d'étage et baies sur les faces verticales
uniform float etage = 3.0;         // hauteur d'étage (m)
uniform float base_y = 0.0;        // altitude du pied du volume (lignes d'étage comptées depuis là)
uniform float hole = 0.0;
// P7.3 (ville V0.6) : volumes à moins de `proche` m de la caméra estompés en trame (un toit juste devant l'objectif
// ne couvre jamais l'écran) ; 0 = sans effet (blockout V0.1 inchangé).
uniform float proche = 0.0;
global uniform vec3 p4_hero;
global uniform float p4_hole;
global uniform float p4_persp;

varying vec3 wpos;
varying vec3 wnrm;

float ligne(float v, float periode, float demi, float fw) {
	float d = abs(fract(v / periode + 0.5) - 0.5) * periode;
	float aa = max(fw, 1e-4);
	return (1.0 - smoothstep(demi - aa, demi + aa, d)) * clamp(demi / aa, 0.15, 1.0);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 c = couleur.rgb;
	if (abs(wnrm.y) > 0.5) {
		if (grille > 0.5) {
			vec2 fw = fwidth(wpos.xz);
			float g = max(ligne(wpos.x, 1.0, 0.012, fw.x), ligne(wpos.z, 1.0, 0.012, fw.y));
			float g5 = max(ligne(wpos.x, 5.0, 0.03, fw.x), ligne(wpos.z, 5.0, 0.03, fw.y));
			c *= 1.0 - 0.08 * g - 0.12 * g5;
		}
	} else if (facade > 0.5) {
		float u = abs(wnrm.x) > 0.5 ? wpos.z : wpos.x;
		float y = wpos.y - base_y;
		float fwy = fwidth(y);
		float fwu = fwidth(u);
		// ligne d'étage (cordon)
		c *= 1.0 - 0.18 * ligne(y, etage, 0.05, fwy);
		// baies : une par travée de 2,5 m, à mi-hauteur de chaque étage (rez-de-chaussée : portes plus hautes)
		float fu = fract(u / 2.5);
		float fy = fract(y / etage);
		float n = floor(y / etage);
		float bu = smoothstep(0.3, 0.3 + fwu / 2.5, fu) * (1.0 - smoothstep(0.7 - fwu / 2.5, 0.7, fu));
		float bas = n < 0.5 ? 0.0 : 0.3;
		float by = smoothstep(bas, bas + fwy / etage, fy) * (1.0 - smoothstep(0.78 - fwy / etage, 0.78, fy));
		c = mix(c, c * 0.42, bu * by * 0.85);
	}
	// léger assombrissement au pied des volumes (lecture du contact au sol)
	if (abs(wnrm.y) < 0.5) {
		c *= 0.82 + 0.18 * smoothstep(0.0, 1.2, wpos.y - base_y);
	}
	ALBEDO = c;
	ROUGHNESS = 1.0;
	if (proche > 0.0) {
		float kp = smoothstep(proche * 0.55, proche, -VERTEX.z);
		float tp = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
		if (kp < tp) { discard; }
	}
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
