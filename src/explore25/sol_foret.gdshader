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

varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float fin(vec2 p) {
	return texture(bruit_fin, p).r;
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

	ALBEDO = mix(src_lin, min(col * luminosite, vec3(1.0)), force);
	ROUGHNESS = 0.95;
	NORMAL = normalize((VIEW_MATRIX * vec4(wnorm, 0.0)).xyz);
}
