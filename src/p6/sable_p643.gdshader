// P6.4.3 — CALQUE DU SABLE de l'arène (affichage seul, posé quelques millimètres au-dessus du sable existant).
// Le sable (texture terre_chemin de P5.3-B) n'est pas modifié : ce calque transparent ajoute seulement
//   1. des variations lentes de teinte (plaques plus sèches et claires, plaques plus tassées et sombres) ;
//   2. des traces d'usage sur les axes réellement parcourus (bouche du tunnel sud -> centre -> tunnel est), au bord
//      irrégulier, avec un piétinement fin ;
//   3. un cercle d'évaluation tracé dans le sable autour du centre (point focal, sans objet ajouté), interrompu par endroits.
// Tout est calculé en coordonnées monde (aucune répétition de tuile) et FILTRÉ (fwidth) : les détails fins s'effacent
// au lieu de scintiller à distance ou aux zooms ×2 / ×3. Éclairé comme le sable (ombres portées comprises).
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, diffuse_lambert, specular_disabled;

uniform vec2 centre = vec2(26.0, 23.0);
uniform vec2 rayons = vec2(12.5, 9.0);        // ellipse du sable
uniform vec4 axe_a = vec4(26.0, 31.6, 26.0, 23.4);   // segment (x0, z0, x1, z1) : bouche du tunnel sud -> centre
uniform vec4 axe_b = vec4(27.0, 23.0, 38.2, 23.0);   // centre -> tunnel est
uniform float largeur = 1.05;                 // demi-largeur des traces (m)
uniform float cercle = 3.3;                   // rayon du cercle d'évaluation (m)
uniform vec4 c_tasse : source_color = vec4(0.36, 0.25, 0.15, 1.0);
uniform vec4 c_sec : source_color = vec4(0.93, 0.80, 0.58, 1.0);
uniform vec4 c_trait : source_color = vec4(0.30, 0.21, 0.13, 1.0);
uniform float k_plaques = 1.0;
uniform float k_traces = 1.0;
uniform float k_cercle = 1.0;

varying vec3 wpos;

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1.0, 0.0)), f.x), mix(h21(i + vec2(0.0, 1.0)), h21(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fnoise(vec2 p, float fw) { return mix(vnoise(p), 0.5, smoothstep(0.25, 0.6, fw)); }
float fbm(vec2 p, float fw) {
	return fnoise(p, fw) * 0.55 + fnoise(p * 2.03 + 7.1, fw * 2.03) * 0.3 + fnoise(p * 4.11 + 3.7, fw * 4.11) * 0.15;
}
float dseg(vec2 p, vec2 a, vec2 b) {
	vec2 ab = b - a;
	float t = clamp(dot(p - a, ab) / dot(ab, ab), 0.0, 1.0);
	return length(p - (a + ab * t));
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xz;
	float fw = max(fwidth(p.x), fwidth(p.y));
	vec2 q = (p - centre) / rayons;
	float r = length(q);
	// rien au pied du podium (la bande de sable tassé existante s'en charge) : fondu sur le dernier mètre
	float dedans = 1.0 - smoothstep(0.86, 0.97, r);
	// 1. plaques lentes : sec et clair / tassé et sombre (grandes formes, contraste faible)
	float n = fbm(p * 0.17 + 3.0, fw * 0.17);
	float sec = smoothstep(0.6, 0.78, n) * 0.08 * k_plaques;
	float tasse = (1.0 - smoothstep(0.28, 0.44, n)) * 0.2 * k_plaques;
	// 2. traces d'usage : bord irrégulier, plus marquées au milieu, piétinement fin
	float bord = (fbm(p * 1.3, fw * 1.3) - 0.5) * 0.7;
	float d = min(dseg(p, axe_a.xy, axe_a.zw), dseg(p, axe_b.xy, axe_b.zw));
	float trace = (1.0 - smoothstep(largeur * 0.35, largeur + 0.25, d + bord)) * 0.36 * k_traces;
	float pas = smoothstep(0.62, 0.8, fnoise(p * 5.5, fw * 5.5)) * (1.0 - smoothstep(0.0, largeur * 1.3, d));
	trace += pas * 0.16 * k_traces;
	// 3. cercle d'évaluation : sillon fin tracé à la main (rayon légèrement irrégulier), interrompu par endroits
	float rr = length(p - centre) + (fnoise(p * 0.9, fw * 0.9) - 0.5) * 0.18;
	float lw = 0.065;
	float aa = max(fw * 0.8, 1e-4);
	float sillon = 1.0 - smoothstep(lw - aa, lw + aa, abs(rr - cercle));
	sillon *= clamp(lw / aa, 0.25, 1.0);                       // trait sous-pixel : contraste réduit (pas de scintillement)
	float coupe = smoothstep(0.3, 0.45, fnoise(vec2(atan(p.y - centre.y, p.x - centre.x) * 2.2, 0.5), 0.0));
	float bourrelet = (1.0 - smoothstep(lw, lw + 0.09, abs(rr - cercle - 0.06))) * (1.0 - sillon);   // sable repoussé
	float k_c = k_cercle * coupe;
	// composition : chaque couche est un voile de couleur au-dessus du sable
	vec3 col = c_sec.rgb;
	float a = sec;
	col = mix(col, c_tasse.rgb, clamp(tasse / max(a + tasse, 1e-4), 0.0, 1.0));
	a = max(a, tasse);
	col = mix(col, c_tasse.rgb, clamp(trace * 2.5, 0.0, 1.0));
	a = max(a, trace);
	col = mix(col, c_sec.rgb, bourrelet * k_c);
	a = max(a, bourrelet * 0.22 * k_c);
	col = mix(col, c_trait.rgb, sillon * k_c);
	a = max(a, sillon * 0.6 * k_c);
	ALBEDO = col;
	ALPHA = clamp(a * dedans, 0.0, 0.65);
}
