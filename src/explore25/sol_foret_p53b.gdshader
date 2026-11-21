// P5.3-B PILOTE (21/11/2026) — P5.3 + matières PEINTES du créateur (herbe drue SOL-01, herbe usée SOL-02, terre de
// chemin SOL-03 ; art/p53/sol/, RGB = couleur, A = hauteur provisoire) dans une ZONE PILOTE (touche Y : carte entière).
// Mélange par hauteur entre les trois matières, pondéré par les masques P5.3 (chemin, bande d'usure, usure de l'herbe) ;
// anti-répétition : second échantillon décalé et à 0,83 de l'échelle, choisi par hauteur selon un bruit large (pas de
// rotation : la peinture contient du volume éclairé). Couleurs restituées telles que peintes (sol plat au soleil).
// Hors zone, pentes, objets, ruisseau : P5.3 inchangé.
// P5.3 — sol de la forêt (exploration et décor de combat). P5.3 : transitions élargies (bande d'usure où l'herbe se
// clairsème au lieu d'un contour), densité / usure de l'herbe, pentes herbe → terre → roche par paliers, contacts en
// lobes ; MOINS de bruit fin (pas de grain, pas de cailloux en points). P5.2 figé : sol_foret_p52.gdshader.
// Historique P5.2 : Même maillage, mêmes collisions : seule la MATIÈRE change.
// La texture peinte V07 (64 px/m, floue) sert de CARTE : chemin (rouge > vert), lit du ruisseau (sombre) ; par-dessus,
// une matière dessinée à l'échelle du personnage, en coordonnées monde (aucune répétition visible à l'écran) :
//  - herbe : trois verts et des plaques sèches à grande échelle, brins clairs et sombres à petite échelle ;
//  - chemin : terre plus claire au centre (piétinée), plus sombre et plus humide sur les bords, petits cailloux ;
//  - raccord chemin / herbe : bord découpé par le bruit (plus de flou), liseré sombre côté herbe, touffes d'herbe qui
//    mordent sur la terre ;
//  - pentes non praticables (> 40° environ) : terre nue et roche, lisibles comme un obstacle ;
//  - pieds des arbres, rochers et buissons : litière brune, ombre de contact (objets posés DANS le sol) ;
//  - micro-relief : normale perturbée par le bruit (la lumière rasante révèle la matière).
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform sampler2D carte : filter_linear_mipmap, repeat_disable;     // texture V07 lue telle quelle (sRGB brut)
uniform sampler2D bruit_large : filter_linear_mipmap, repeat_enable;
uniform sampler2D bruit_fin : filter_linear_mipmap, repeat_enable;
uniform vec4 obstacles[128];      // x, z, rayon, nature (0 arbre, 1 rocher, 2 buisson)
uniform int nb_obstacles = 0;
uniform float force = 1.0;        // 0 : texture V07 d'origine (comparaison)

uniform vec4 herbe_sombre : source_color = vec4(0.144, 0.164, 0.088, 1.0);   // affiché ≈ (72, 82, 44)
uniform vec4 herbe_moyenne : source_color = vec4(0.192, 0.208, 0.112, 1.0);   // affiché ≈ (96, 104, 56)
uniform vec4 herbe_claire : source_color = vec4(0.248, 0.256, 0.144, 1.0);   // affiché ≈ (124, 128, 72)
uniform vec4 herbe_seche : source_color = vec4(0.264, 0.236, 0.14, 1.0);   // affiché ≈ (132, 118, 70)
uniform vec4 terre_bord : source_color = vec4(0.224, 0.172, 0.116, 1.0);   // affiché ≈ (112, 86, 58)
uniform vec4 terre_centre : source_color = vec4(0.304, 0.24, 0.164, 1.0);   // affiché ≈ (152, 120, 82)
uniform vec4 caillou : source_color = vec4(0.34, 0.324, 0.288, 1.0);   // affiché ≈ (170, 162, 144)
uniform vec4 litiere : source_color = vec4(0.184, 0.132, 0.08, 1.0);   // affiché ≈ (92, 66, 40)
uniform vec4 terre_pente : source_color = vec4(0.224, 0.176, 0.124, 1.0);   // affiché ≈ (112, 88, 62)
uniform vec4 roche : source_color = vec4(0.244, 0.236, 0.216, 1.0);   // affiché ≈ (122, 118, 108)
uniform float relief = 0.0;          // micro-relief par le bruit : hachures sous le soleil rasant, retiré (réglable)
// avec de vraies normales, le sol reçoit sin(48°) du soleil au lieu de tout : compensation de la matière, pour garder
// la luminosité générale du sol V07 validé. Couleurs ci-dessus : valeur linéaire ≈ couleur AFFICHÉE au soleil sur sol
// plat / 500 (mesuré sur le rendu ; sol V07 affiché : herbe ≈ (100, 95, 52), chemin ≈ (159, 94, 47))
uniform float luminosite = 2.5;
uniform float largeur_usure = 1.0;   // > 1 : bande d'usure des chemins plus large
// --- P5.3-B
uniform sampler2D tex_drue : source_color, filter_linear_mipmap_anisotropic, repeat_enable;     // valeurs brutes (sRGB peint)
uniform sampler2D tex_usee : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_terre : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float tuile_m = 4.0;                    // 1024 px = 4 m (256 px/m)
uniform vec3 zone_pilote = vec3(-10.0, 1.0, 8.0);   // x, z, rayon (m)
uniform float fondu_zone = 1.5;
uniform bool carte_entiere = false;
uniform float force_hauteur = 4.0;              // V1 : hauteurs (écart type ≈ 0,05) étirées autour de leur moyenne
// centre des hauteurs par matière. V1 (hauteurs relatives, ≈ 0,45) : centrées sur leur moyenne. V2 (hauteurs ABSOLUES :
// herbe ≈ 0,89, terre ≈ 0,28, herbe usée bimodale) : centre commun 0,5 et force faible (l'herbe passe au-dessus de la terre)
uniform float moy_drue = 0.45;
uniform float moy_usee = 0.45;
uniform float moy_terre = 0.43;
uniform float test_usure = 0.0;                 // outil : 1 = herbe usée imposée dans la zone (contrôle de sa répétition)
uniform float profondeur_melange = 0.08;
// --- P5.3-B V2 « transitions » (21/11/2026), sans effet sur V1 / V1 calée / V2 actuelle (valeurs par défaut) :
//  - force_mat : étirement des hauteurs PAR MATIÈRE autour de leur moyenne (0 : force_hauteur commune). Les hauteurs V2
//    sont absolues et presque plates à l'intérieur d'une matière (écart type herbe 0,031, terre 0,018) : sans
//    étirement, le mélange ne trouve aucun relief pour découper le bord et reproduit le contour lisse du masque ;
//  - transition > 0 : bande intermédiaire herbe drue → herbe usée → terre, de largeur variable, à la place de la
//    simple frontière herbe / terre (la forme et le cœur praticable des chemins ne changent pas).
uniform vec3 force_mat = vec3(0.0);
uniform vec3 biais_mat = vec3(0.0);             // décalage de priorité (drue, usée, terre)
uniform float transition = 0.0;
uniform vec2 largeur_bande = vec2(0.14, 0.32);  // largeur de la bande intermédiaire (unités du masque b), min / max
// le masque du chemin (carte V07 à 64 px/m) passe de 0 à 1 sur ≈ 40 cm : toute bande définie dessus reste étroite.
// La bande intermédiaire utilise la PROXIMITÉ du chemin : moyenne du masque sur deux anneaux de 8 lectures
// (rayons rayon_proximite.x et .y, en mètres ; la carte n'a pas de mipmaps exploitables)
uniform vec2 rayon_proximite = vec2(0.55, 1.1);
const vec2 CARTE_M = vec2(36.0, 28.0);          // étendue de la carte V07 (m) : UV = (x + 18) / 36, (z + 14) / 28
uniform int debug_poids = 0;                    // outil : 1 = affiche les poids (rouge herbe dense, vert usée, bleu terre)
uniform float anti_repetition = 1.0;            // 0 : un seul échantillon (répétition brute, comparaison)
// couleur peinte décodée en linéaire × gain. ÉTALONNÉ (tools/p5/captures_sol.gd --etalon) : couleur unie = moyenne
// peinte de la terre (117, 68, 51) ; sol plat au soleil affiché (143, 74, 42) à 0,30, (160, 82, 47) à 0,40 ;
// 0,22 rend la luminosité peinte (≈ 81 / 255) ; la teinte reste réchauffée par le soleil orangé de la scène
uniform float gain_peint = 0.22;
uniform vec4 etalon : source_color = vec4(0.0);
// ESSAI de calage (0 = couleurs peintes telles quelles, défaut du pilote) : ramène la teinte MOYENNE de chaque matière
// vers la palette de la forêt (P5.3), le détail peint restant intact ; sert uniquement à la discussion avec le créateur
uniform float calage = 0.0;
const vec3 MOY_DRUE = vec3(0.0231, 0.0869, 0.0316);     // moyennes peintes (46, 84, 53), (76, 76, 51), (117, 68, 51) en linéaire
const vec3 MOY_USEE = vec3(0.0697, 0.0697, 0.029);
const vec3 MOY_TERRE = vec3(0.1801, 0.0546, 0.029);
const vec3 PAL_DRUE = vec3(0.0892, 0.1139, 0.0278);     // palette P5.3 (affiché ≈ (85, 95, 50), (128, 116, 72), (140, 110, 74))
const vec3 PAL_USEE = vec3(0.2195, 0.1768, 0.0619);
const vec3 PAL_TERRE = vec3(0.2674, 0.1573, 0.0658);   // outil d'étalonnage : a > 0 -> couleur unie (moyenne peinte) au lieu des textures

varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float fin(vec2 p) {
	return texture(bruit_fin, p).r;
}

vec4 peint(sampler2D t, vec2 p, float m, float moyenne, float etirement) {
	vec4 a = texture(t, p / tuile_m);
	vec4 b = texture(t, p / (tuile_m * 0.83) + vec2(0.37, 0.61));
	float f = etirement > 0.0 ? etirement : force_hauteur;
	float ha = (a.a - moyenne) * f;
	float hb = (b.a - moyenne) * f;
	float w = smoothstep(0.42, 0.58, m + (hb - ha) * 0.5) * anti_repetition;
	vec4 c = mix(a, b, w);
	return vec4(c.rgb * gain_peint, mix(ha, hb, w));
}

vec3 melange_hauteur(vec4 a, vec4 b, vec4 c, float wa, float wb, float wc) {
	float ha = a.a + wa;
	float hb = b.a + wb;
	float hc = c.a + wc;
	float m = max(max(ha, hb), hc) - profondeur_melange;
	float ka = max(ha - m, 0.0);
	float kb = max(hb - m, 0.0);
	float kc = max(hc - m, 0.0);
	return (a.rgb * ka + b.rgb * kb + c.rgb * kc) / max(ka + kb + kc, 1e-4);
}

void fragment() {
	vec3 src = texture(carte, UV).rgb;                       // valeurs sRGB brutes (masques)
	vec3 src_lin = pow(src, vec3(2.2));
	vec2 p = wpos.xz;
	// bruits : grande et moyenne échelle seulement (taches de 1 à 20 m) ; le bruit fin (d3, ≈ 50 cm) n'est plus utilisé
	float m1 = texture(bruit_large, p / 23.0).r;
	float m2 = texture(bruit_large, p / 8.7 + vec2(0.37, 0.11)).r;
	float d1 = fin(p / 3.1);
	float d2 = fin(p / 1.27 + vec2(0.5, 0.21));

	// --- cartes : chemin (dégradé naturel de la carte V07, ≈ 40 cm) et lit du ruisseau
	float chemin_doux = smoothstep(-0.012, 0.075, src.r - src.g);
	float lum = dot(src, vec3(0.299, 0.587, 0.114));
	float lit = smoothstep(-0.035, 0.0, src.b - src.r) * smoothstep(0.30, 0.265, lum) * step(src.r, src.g);
	// bord : irrégularité à grande échelle seulement (m2 ≈ 9 m, d1 ≈ 3 m)
	float b = chemin_doux + (m2 - 0.5) * 0.34 + (d1 - 0.5) * 0.16;
	// trois zones : herbe pleine | bande d'usure (herbe clairsemée, plaques de terre) | terre
	float usure_chemin = smoothstep(0.06, 0.5 / largeur_usure + 0.06, b);
	float plaques = smoothstep(0.5, 0.66, b + (d2 - 0.5) * 0.42);      // terre qui apparaît par plaques (≈ 1 m)
	float terre_t = max(smoothstep(0.5, 0.68, b), plaques * usure_chemin);
	float centre = smoothstep(0.7, 1.0, chemin_doux);

	// --- pentes : herbe qui se clairsème, puis terre, puis roche (paliers par la pente, à peine décalés par m2)
	float ny = wnorm.y + (m2 - 0.5) * 0.05;
	float pente_usure = smoothstep(0.95, 0.86, ny);
	float pente_terre = smoothstep(0.87, 0.78, ny);
	float pente_roche = smoothstep(0.79, 0.70, ny);

	// --- pieds des objets : formes en lobes (sinus de l'angle, pas de bruit), litière, racines, terre remontée
	float lt = 0.0;
	float contact = 0.0;
	float racines = 0.0;
	float mousse = 0.0;
	float dense = 0.0;
	for (int i = 0; i < nb_obstacles; i++) {
		vec4 o = obstacles[i];
		vec2 v = p - o.xy;
		float d = length(v);
		if (d > o.z + 1.4) {
			continue;
		}
		float a = atan(v.y, v.x);
		float lobe = 1.0 + 0.16 * sin(a * 5.0 + o.x * 1.7) + 0.09 * sin(a * 3.0 + o.y * 2.3);
		float dl = d / lobe;
		if (o.w < 0.5) {                                     // arbre
			lt = max(lt, smoothstep(o.z, o.z * 0.35, dl));
			racines = max(racines, smoothstep(0.55, 0.95, sin(a * 6.0 + o.x * 3.1)) * smoothstep(0.75, 0.25, d));
			contact = max(contact, smoothstep(0.6, 0.15, d));
		} else if (o.w < 1.5) {                              // rocher : terre remontée et mousse au pied
			lt = max(lt, 0.45 * smoothstep(o.z + 0.7, o.z, dl));
			mousse = max(mousse, smoothstep(o.z + 0.35, o.z * 0.9, dl));
			contact = max(contact, smoothstep(o.z + 0.25, o.z * 0.85, dl));
		} else {                                             // buisson : herbe plus drue et ombre au pied
			dense = max(dense, smoothstep(o.z * 1.3, o.z * 0.5, dl));
			contact = max(contact, 0.55 * smoothstep(o.z * 0.7, o.z * 0.2, dl));
		}
	}

	// --- herbe : drue (sombre, saturée) ou usée (claire, jaunie, terre visible) selon l'usure
	float usure = clamp(max(max(usure_chemin * 0.85, pente_usure * 0.75), max(lt * 0.5, smoothstep(0.62, 0.86, m1) * 0.35)) - dense * 0.5, 0.0, 1.0);
	vec3 drue = mix(herbe_sombre.rgb, herbe_moyenne.rgb, smoothstep(0.25, 0.75, m1));
	drue = mix(drue, herbe_claire.rgb, smoothstep(0.6, 0.9, m2) * 0.45);
	vec3 usee = mix(herbe_seche.rgb, terre_bord.rgb, 0.3);
	vec3 herbe = mix(drue, usee, usure);
	herbe *= 0.95 + 0.1 * d2;                                 // variation douce (≈ 1 m), pas de grain

	// --- terre du chemin : plus claire au centre, plus sombre et humide sur les bords
	vec3 terre = mix(terre_bord.rgb, terre_centre.rgb, centre);
	terre *= 0.95 + 0.1 * d1;
	terre = mix(terre, terre_bord.rgb * 0.85, smoothstep(0.66, 0.8, m2) * (1.0 - centre) * 0.45);

	vec3 col = mix(herbe, terre, terre_t);
	// --- P5.3-B : matières peintes (zone pilote)
	float zp = carte_entiere ? 1.0 : smoothstep(zone_pilote.z, zone_pilote.z - fondu_zone, distance(p, zone_pilote.xy));
	if (zp > 0.0) {
		float mr = texture(bruit_large, p / 11.0 + vec2(0.71, 0.29)).r;
		vec4 td = peint(tex_drue, p, mr, moy_drue, force_mat.x);
		vec4 tu = peint(tex_usee, p, 1.0 - mr, moy_usee, force_mat.y);
		vec4 tt = peint(tex_terre, p, mr, moy_terre, force_mat.z);
		td.a += biais_mat.x;
		tu.a += biais_mat.y;
		tt.a += biais_mat.z;
		td.rgb *= mix(vec3(1.0), PAL_DRUE / MOY_DRUE, calage);
		tu.rgb *= mix(vec3(1.0), PAL_USEE / MOY_USEE, calage);
		tt.rgb *= mix(vec3(1.0), PAL_TERRE / MOY_TERRE, calage);
		float us = max(usure, test_usure);
		float wt = terre_t * (1.0 - test_usure);
		float wu = us * (1.0 - wt);
		float wd = (1.0 - us) * (1.0 - wt);
		if (transition > 0.0) {
			// bande intermédiaire : largeur variable le long du chemin (m1 ≈ 23 m, m2 ≈ 9 m), position déjà irrégulière
			// dans b (m2, d1) ; aucune échelle plus fine que d2 (≈ 1,3 m), pour rester doux à l'échelle du jeu
			float lb = mix(largeur_bande.x, largeur_bande.y, clamp(m1 * 0.6 + m2 * 0.6 - 0.1, 0.0, 1.0));
			float a1 = 0.0;
			float a2 = 0.0;
			for (int k = 0; k < 8; k++) {
				float ang = float(k) * 0.7854 + 0.39;
				vec2 dir = vec2(cos(ang), sin(ang)) / CARTE_M;
				vec3 c1 = textureLod(carte, UV + dir * rayon_proximite.x, 0.0).rgb;
				vec3 c2 = textureLod(carte, UV + dir * rayon_proximite.y, 0.0).rgb;
				a1 += smoothstep(-0.012, 0.075, c1.r - c1.g);
				a2 += smoothstep(-0.012, 0.075, c2.r - c2.g);
			}
			float prox = max(a1 / 8.0, a2 / 8.0 * 0.8);                       // 0 loin, ≈ 0,5 au bord, 1 dans le chemin
			// variations à 3 échelles seulement (≈ 9 m, 3 m, 1,3 m), amplitudes modérées : bord irrégulier mais doux
			float pn = clamp(prox + (m2 - 0.5) * 0.30 + (d1 - 0.5) * 0.18 + (d2 - 0.5) * 0.08, 0.0, 1.0);
			// transition centrée sur le bord d'origine du chemin (pn ≈ 0,5) : la forme et le cœur restent les mêmes
			float t_terre = max(smoothstep(0.42, 0.86, pn), smoothstep(0.72, 0.92, b));   // cœur du chemin : terre pleine
			float t_drue = 1.0 - smoothstep(0.10, 0.40 + lb * 0.5, pn);                    // herbe dense : s'efface (≈ 1 m)
			float t_usee = smoothstep(0.08, 0.42, pn) * (1.0 - smoothstep(0.60, 0.95, pn) * 0.85);   // herbe clairsemée
			// usure P5.3 hors chemins (pentes, sous les arbres, grandes zones) : conservée
			float us_hors = clamp(max(max(pente_usure * 0.75, lt * 0.5), smoothstep(0.62, 0.86, m1) * 0.35) - dense * 0.5, 0.0, 1.0);
			t_usee = max(t_usee, us_hors * t_drue);
			t_drue *= 1.0 - us_hors;
			wt = mix(wt, t_terre * (1.0 - test_usure), transition);
			wu = mix(wu, max(t_usee, test_usure), transition);
			wd = mix(wd, t_drue * (1.0 - test_usure), transition);
		}
		vec3 cp = etalon.a > 0.0 ? etalon.rgb * gain_peint : melange_hauteur(td, tu, tt, wd, wu, wt);
		if (debug_poids == 1) {
			cp = vec3(wd, wu, wt) * 0.35;
		}
		col = mix(col, cp, zp);
	}
	col *= 1.0 - 0.07 * smoothstep(0.35, 0.5, b) * (1.0 - smoothstep(0.5, 0.65, b));   // très léger tassement au bord

	// --- pentes
	vec3 terre_p = terre_pente.rgb * (0.95 + 0.1 * d1);
	// roche : variations larges seulement (des strates par l'altitude se lisaient comme des courbes de niveau ; la
	// matière de roche viendra d'une texture peinte, étape B)
	vec3 roc = roche.rgb * (0.84 + 0.22 * m1) * (0.94 + 0.1 * m2);
	col = mix(col, terre_p, pente_terre * 0.85);
	col = mix(col, roc, pente_roche * 0.9);

	// --- objets
	col = mix(col, litiere.rgb * (0.9 + 0.15 * d2), lt * 0.65 * (1.0 - terre_t * 0.6));
	col = mix(col, litiere.rgb * 0.75, racines * 0.35);
	col = mix(col, herbe_sombre.rgb * 0.9, mousse * 0.5 * (1.0 - terre_t));
	col = mix(col, herbe_sombre.rgb, dense * 0.35 * (1.0 - terre_t));
	col *= 1.0 - contact * 0.36;

	// --- lit du ruisseau : couleur peinte d'origine, assombrie
	col = mix(col, src_lin * 0.85, lit);

	ALBEDO = mix(src_lin, min(col * luminosite, vec3(mix(1.0, 3.0, zp))), force);   // pas d'écrêtage à 1 sur le peint
	ROUGHNESS = 0.95;
	NORMAL = normalize((VIEW_MATRIX * vec4(wnorm, 0.0)).xyz);
}
