shader_type spatial;
// P6.2-C / P6.2-D — VUE DEPUIS LE TUNNEL des combattants (Colisée).
// Quad plein écran dessiné après la scène ; la position monde de chaque pixel est reconstruite depuis la profondeur.
//  1. Lignes de vue : un point de l'extérieur n'est visible que si le segment (Aren -> point), vu du dessus, passe par
//     l'ouverture de la bouche (x0..x1 sur la ligne z = bouche_z). Hors de ce cône : la pénombre du tunnel (couleur).
//  2. P6.2-D — éblouissement : dans le cône, au-delà d'une portée qui grandit à mesure qu'Aren avance (portee), la vue
//     est noyée dans la lumière du jour (jour, alpha eblouit) : depuis l'entrée, une ouverture lumineuse ; au milieu, la
//     silhouette du commandant dans la lumière ; à la fin, les premiers mètres de sable ; au débouché (amount -> 0), tout.
//  3. P6.2-D — ferme : masque complet (seuil salle / tunnel). Le changement de pièce se fait sous un masque fermé : le
//     reste du niveau, en cours d'apparition (transparent, donc sans profondeur), n'est jamais montré.
// Aucun maillage, matériau ou collision n'est modifié : affichage seulement.
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, blend_mix, fog_disabled, shadows_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform vec2 eye = vec2(26.0, 34.0);          // Aren (x, z monde)
uniform vec3 bouche = vec3(24.5, 27.5, 32.0); // x0, x1, z de la ligne de la bouche
uniform vec4 interieur0 = vec4(15.5, 37.0, 36.5, 56.0); // rectangles (x0, z0, x1, z1) jamais masqués : le bâtiment
uniform vec4 interieur1 = vec4(24.0, 31.95, 28.0, 37.6);
uniform float amount = 1.0;                   // 0 : aucun masque ; 1 : masque complet
uniform float douceur = 0.18;                 // m sur la ligne de la bouche (bord adouci du cône)
uniform vec3 couleur : source_color = vec3(0.05, 0.04, 0.045);
uniform float portee = 100.0;                 // m depuis la bouche : au-delà, éblouissement
uniform float eblouit = 0.0;                  // opacité de la lumière du jour au-delà de la portée
uniform vec3 jour : source_color = vec3(0.96, 0.88, 0.72);
uniform float ferme = 0.0;                    // 1 : tout l'extérieur masqué
uniform int debug = 0;                        // 1 : position monde reconstruite (diagnostic)

void vertex() {
	POSITION = vec4(VERTEX.xy * 2.0, 1.0, 1.0);
}

bool dans(vec4 r, vec2 p) {
	return p.x >= r.x && p.x <= r.z && p.y >= r.y && p.y <= r.w;
}

void fragment() {
	float depth = texture(depth_tex, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	vec3 world = (INV_VIEW_MATRIX * vec4(view.xyz, 1.0)).xyz;
	vec2 p = world.xz;
	float masque = 0.0;
	float lumiere = 0.0;
	if (depth <= 1e-6) {
		masque = max(ferme, 1.0);           // P6.2-D : vide autour du bâtiment (aucune géométrie) : pénombre, jamais de lumière
	} else if (!(dans(interieur0, p) || dans(interieur1, p))) {
		float z0 = bouche.z;
		float c = 0.5 * (bouche.x + bouche.y);
		if (p.y >= z0 - 0.001 || eye.y <= z0 + 0.001) {
			masque = 1.0;               // derrière la ligne de la bouche (gradins sud, côtés) : caché par les murs
			if (eye.y <= z0 + 0.001 && p.y < z0) {
				masque = 0.0;           // Aren dans la bouche : tout l'avant est en vue
			}
		} else {
			float t = (eye.y - z0) / max(eye.y - p.y, 1e-4);
			float xi = eye.x + (p.x - eye.x) * t;  // passage du rayon sur la ligne de la bouche
			float w = 0.5 * (bouche.y - bouche.x);
			masque = smoothstep(w - douceur, w + douceur, abs(xi - c));
			float d = length(p - vec2(c, z0));
			lumiere = (1.0 - masque) * smoothstep(portee - 1.5, portee + 2.5, d) * eblouit;
		}
		masque = max(masque, ferme);
	}
	vec3 col = mix(couleur, jour, lumiere / max(lumiere + masque * (1.0 - lumiere), 1e-4));
	ALBEDO = col;
	ALPHA = clamp(masque + lumiere, 0.0, 1.0) * amount;
	if (debug == 1) {
		ALBEDO = vec3(fract(p.x / 4.0), fract(p.y / 4.0), masque);
		ALPHA = 1.0;
	}
}
