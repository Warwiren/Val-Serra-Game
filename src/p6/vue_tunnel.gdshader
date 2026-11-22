shader_type spatial;
// P6.2-C — VUE DEPUIS LE TUNNEL : lignes de vue réelles à travers la bouche du tunnel du Colisée.
// Quad plein écran, dessiné après la scène : la position monde de chaque pixel est reconstruite depuis la profondeur. Un
// point de l'extérieur n'est visible que si le segment (Aren -> point), vu du dessus, passe par l'ouverture de la bouche
// (x0..x1 sur la ligne z = bouche_z). Le reste prend la couleur sombre de l'intérieur (comme derrière les murs du tunnel).
// Plus Aren approche de la bouche, plus le cône s'ouvre ; à la sortie, le masque s'efface (amount, réglé par la scène).
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
	if (!(dans(interieur0, p) || dans(interieur1, p))) {
		float z0 = bouche.z;
		if (p.y >= z0 - 0.001 || eye.y <= z0 + 0.001) {
			masque = 1.0;               // derrière la ligne de la bouche (gradins sud, côtés) : caché par les murs
			if (eye.y <= z0 + 0.001 && p.y < z0) {
				masque = 0.0;           // Aren dans la bouche : tout l'avant est en vue
			}
		} else {
			float t = (eye.y - z0) / max(eye.y - p.y, 1e-4);
			float xi = eye.x + (p.x - eye.x) * t;  // passage du rayon sur la ligne de la bouche
			float c = 0.5 * (bouche.x + bouche.y);
			float w = 0.5 * (bouche.y - bouche.x);
			masque = smoothstep(w - douceur, w + douceur, abs(xi - c));
		}
	}
	ALBEDO = couleur;
	ALPHA = masque * amount;
	if (debug == 1) {
		ALBEDO = vec3(fract(p.x / 4.0), fract(p.y / 4.0), masque);
		ALPHA = 1.0;
	}
}
