// P5.2 FIGÉ (21/11/2026) : copie de comparaison du sol P5.2 (touche U). Version courante : sol_foret.gdshader (P5.3).
// P5.2 — sol de la forêt (exploration et décor de combat). Même maillage, mêmes collisions : seule la MATIÈRE change.
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
uniform vec4 terre_pente : source_color = vec4(0.244, 0.192, 0.14, 1.0);   // affiché ≈ (122, 96, 70)
uniform vec4 roche : source_color = vec4(0.264, 0.256, 0.236, 1.0);   // affiché ≈ (132, 128, 118)
uniform float relief = 0.0;          // micro-relief par le bruit : hachures sous le soleil rasant, retiré (réglable)
// avec de vraies normales, le sol reçoit sin(48°) du soleil au lieu de tout : compensation de la matière, pour garder
// la luminosité générale du sol V07 validé. Couleurs ci-dessus : valeur linéaire ≈ couleur AFFICHÉE au soleil sur sol
// plat / 500 (mesuré sur le rendu ; sol V07 affiché : herbe ≈ (100, 95, 52), chemin ≈ (159, 94, 47))
uniform float luminosite = 2.5;

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
	float m1 = texture(bruit_large, p / 23.0).r;
	float m2 = texture(bruit_large, p / 8.7 + vec2(0.37, 0.11)).r;
	float d1 = fin(p / 3.1);
	float d2 = fin(p / 1.27 + vec2(0.5, 0.21));
	float d3 = fin(p / 0.53 + vec2(0.13, 0.77));

	// --- cartes : chemin (terre ocre : rouge nettement au-dessus du vert) et lit du ruisseau (sombre, vert > rouge)
	float chemin_doux = smoothstep(-0.012, 0.075, src.r - src.g);
	float lum = dot(src, vec3(0.299, 0.587, 0.114));
	// lit : bleu-vert sombre (bleu au niveau du rouge), à ne pas confondre avec l'herbe foncée (bleu bien sous le rouge)
	float lit = smoothstep(-0.035, 0.0, src.b - src.r) * smoothstep(0.30, 0.265, lum) * step(src.r, src.g);
	float bord = chemin_doux + (m2 - 0.5) * 0.5 + (d1 - 0.5) * 0.32 + (d3 - 0.5) * 0.2;   // bord irrégulier à 3 échelles
	float chemin = smoothstep(0.46, 0.56, bord);
	float centre = smoothstep(0.78, 1.0, chemin_doux + (d1 - 0.5) * 0.25);

	// --- herbe
	vec3 herbe = mix(herbe_sombre.rgb, herbe_moyenne.rgb, smoothstep(0.3, 0.72, m1));
	herbe = mix(herbe, herbe_claire.rgb, smoothstep(0.55, 0.85, m2) * 0.65);
	herbe = mix(herbe, herbe_seche.rgb, smoothstep(0.62, 0.82, m1) * (1.0 - m2) * 0.55);
	herbe *= 0.86 + 0.28 * d2;                              // brins : clair / sombre
	herbe = mix(herbe, herbe_claire.rgb, smoothstep(0.74, 0.86, d3) * 0.3);
	herbe = mix(herbe, herbe_sombre.rgb * 0.85, smoothstep(0.26, 0.14, d3) * 0.3);

	// --- terre du chemin
	vec3 terre = mix(terre_bord.rgb, terre_centre.rgb, centre);
	terre *= 0.9 + 0.14 * d1 + 0.12 * d3;                  // variations larges, grain de terre discret (≈ 5 cm)
	terre = mix(terre, terre_bord.rgb * 0.82, smoothstep(0.66, 0.78, m2) * (1.0 - centre) * 0.5);   // plaques humides
	float cail = smoothstep(0.80, 0.85, d3) * smoothstep(0.5, 0.72, d1);              // petits cailloux, en groupes
	terre = mix(terre, caillou.rgb * (0.9 + 0.2 * d3), cail * 0.7);

	// --- raccord
	vec3 col = mix(herbe, terre, chemin);
	float levre = smoothstep(0.32, 0.46, bord) * (1.0 - smoothstep(0.46, 0.6, bord));
	col *= 1.0 - levre * 0.16;
	float touffes = smoothstep(0.72, 0.82, d2) * (1.0 - smoothstep(0.45, 0.7, chemin_doux)) * chemin;   // bords seulement
	col = mix(col, herbe * 1.04, touffes);

	// --- pentes non praticables : terre nue puis roche
	float pente = smoothstep(0.80, 0.70, wnorm.y);
	vec3 roc = mix(terre_pente.rgb * (0.92 + 0.14 * d1), roche.rgb * (0.88 + 0.2 * m2), smoothstep(0.5, 0.66, d1 + m2 * 0.3));
	col = mix(col, roc, pente * 0.9);

	// --- pieds des objets : litière et ombre de contact
	float lt = 0.0;
	float contact = 0.0;
	for (int i = 0; i < nb_obstacles; i++) {
		vec4 o = obstacles[i];
		float d = distance(p, o.xy) + (d1 - 0.5) * 0.45;
		if (o.w < 0.5) {
			lt = max(lt, smoothstep(o.z, o.z * 0.3, d));
			contact = max(contact, smoothstep(0.6, 0.18, d));
		} else if (o.w < 1.5) {
			lt = max(lt, 0.55 * smoothstep(o.z + 0.8, o.z, d));
			contact = max(contact, smoothstep(o.z + 0.3, o.z * 0.85, d));
		} else {
			lt = max(lt, 0.6 * smoothstep(o.z, o.z * 0.4, d));
			contact = max(contact, 0.6 * smoothstep(o.z * 0.7, o.z * 0.2, d));
		}
	}
	col = mix(col, litiere.rgb * (0.8 + 0.4 * d2) , lt * 0.7 * (1.0 - chemin * 0.6));
	col = mix(col, col * vec3(1.18, 0.92, 0.7), lt * smoothstep(0.76, 0.86, d2) * 0.5);  // feuilles mortes
	col *= 1.0 - contact * 0.38;

	// --- lit du ruisseau : couleur peinte d'origine, assombrie
	col = mix(col, src_lin * 0.85, lit);

	ALBEDO = mix(src_lin, min(col * luminosite, vec3(1.0)), force);
	ROUGHNESS = 0.95;

	// micro-relief (gradient du bruit fin), plus marqué sur la terre et la roche
	float e = 0.06;
	float h0 = fin(p / 2.4);
	vec2 g = vec2(fin((p + vec2(e, 0.0)) / 2.4) - h0, fin((p + vec2(0.0, e)) / 2.4) - h0) / e;
	float k = relief * mix(0.3, 0.45, max(chemin, pente)) * force;
	vec3 nw = normalize(wnorm - vec3(g.x, 0.0, g.y) * k);
	NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);
}
