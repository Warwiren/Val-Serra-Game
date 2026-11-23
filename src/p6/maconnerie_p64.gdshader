// P6.4 — PILOTE de matériaux du Colisée : maçonnerie, dallage, planches et tuiles PROCÉDURAUX.
// Le calepinage (assises, blocs, dalles, lames, tuiles) est calculé dans le shader, en mètres, à partir d'UV cohérentes
// avec la géométrie (UV du maillage en mètres, ou UV monde pour les faces planes alignées). Chaque élément a sa propre
// teinte, sa salissure et son usure : aucune répétition de tuile de texture. Les joints sont FILTRÉS (largeur comparée
// à la taille du pixel, fwidth) : à distance ou en angle rasant, ils se fondent en une teinte moyenne au lieu de
// scintiller. Relief par dérivées d'écran (biseaux, joints creux, tuiles bombées), affaibli lui aussi avec la distance.
// La texture de grain (facultative) n'apporte que des variations de luminance à basse fréquence, avec mipmaps.
// « Trou » tramé autour du héros identique à surface_p4.gdshader (occlusion validée en forêt, non modifiée).
shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;

uniform int motif = 0;              // 0 : appareil de pierre ; 1 : dallage ; 2 : planches ; 3 : tuiles canal
uniform float uv_mode = 1.0;        // 0 : UV monde ; 1 : UV du maillage (en mètres × uv_m)
uniform float uv_m = 1.0;           // mètres par unité d'UV du maillage
uniform vec3 assises = vec3(0.42, 0.30, 0.36);   // hauteurs des assises (motif répété de trois)
uniform float long_bloc = 0.9;      // longueur moyenne d'un bloc (m)
uniform float var_long = 0.45;      // variation de longueur d'une assise à l'autre
uniform float joint = 0.014;        // demi-largeur du joint (m)
uniform float biseau = 0.035;       // largeur du biseau des arêtes (m)
uniform vec4 couleur : source_color = vec4(0.74, 0.66, 0.55, 1.0);
uniform vec4 couleur2 : source_color = vec4(0.62, 0.58, 0.52, 1.0);   // seconde famille de pierre (mêlée par bloc)
uniform vec4 c_joint : source_color = vec4(0.34, 0.30, 0.27, 1.0);
uniform float var_teinte = 0.10;    // écart de luminosité d'un élément à l'autre
uniform float part2 = 0.3;          // proportion d'éléments de la seconde famille
uniform float salissure = 0.35;     // pied des murs plus sombre (hauteur monde)
uniform float coulures = 0.25;      // coulures verticales sous les arêtes hautes
uniform float mousse = 0.12;        // verdissement au pied et dans les joints
uniform float usure = 0.3;          // arêtes épaufrées, dalles polies
uniform float relief = 1.0;
uniform sampler2D grain : source_color, repeat_enable, filter_linear_mipmap;
uniform float grain_k = 0.0;        // 0 : pas de texture de grain
uniform float grain_m = 1.6;        // taille du grain (m)
uniform float hole = 0.0;
uniform float base_y = 0.0;         // hauteur du sol de référence (salissure)
uniform float valeur = 0.8;         // valeur générale (étalonnée sur l'éclairage du Colisée)
uniform float modele = 0.12;        // modelé peint de chaque pierre (haut plus clair, bas plus sombre)
global uniform vec3 p4_hero;
global uniform float p4_hole;
global uniform float p4_persp;

varying vec3 wpos;
varying vec3 wnrm;

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float h11(float p) { return fract(sin(p * 91.345) * 47453.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1.0, 0.0)), f.x), mix(h21(i + vec2(0.0, 1.0)), h21(i + vec2(1.0, 1.0)), f.x), f.y);
}
// bruit filtré : s'éteint quand sa période devient plus petite que deux pixels (pas de crépitement à distance)
float fnoise(vec2 p, float fw) {
	return mix(vnoise(p), 0.5, smoothstep(0.25, 0.6, fw));
}

// Calepinage : assise (rangée) puis élément dans l'assise. Retourne l'identifiant de l'élément (xy), les coordonnées
// locales (zw, en m) ; d_bord = distance au joint le plus proche ; taille = dimensions de l'élément.
void calepin(vec2 p, out vec2 id, out vec2 loc, out float d_bord, out vec2 taille) {
	float cycle = assises.x + assises.y + assises.z;
	float k = floor(p.y / cycle);
	float yy = p.y - k * cycle;
	float row; float h; float y0;
	if (yy < assises.x) { row = 0.0; h = assises.x; y0 = 0.0; }
	else if (yy < assises.x + assises.y) { row = 1.0; h = assises.y; y0 = assises.x; }
	else { row = 2.0; h = assises.z; y0 = assises.x + assises.y; }
	float r = k * 3.0 + row;
	float L = long_bloc * (1.0 + var_long * (h11(r * 1.7 + 3.1) * 2.0 - 1.0));
	float off = h11(r + 0.37) * L;
	float xx = p.x + off;
	float b = floor(xx / L);
	// un élément sur quatre est plus long ou plus court (coupe le rythme régulier)
	float lx = xx - b * L;
	id = vec2(b, r);
	loc = vec2(lx, yy - y0);
	taille = vec2(L, h);
	d_bord = min(min(loc.x, L - loc.x), min(loc.y, h - loc.y));
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 p;
	if (uv_mode < 0.5) {
		if (abs(wnrm.y) > 0.5) { p = wpos.xz; }
		else if (abs(wnrm.x) > 0.5) { p = vec2(wpos.z, wpos.y); }
		else { p = vec2(wpos.x, wpos.y); }
	} else {
		p = UV * uv_m;
		p.y = -p.y;                     // les UV des faces ont v = -hauteur
	}
	vec2 id; vec2 loc; float d; vec2 taille;
	calepin(p, id, loc, d, taille);
	float fw = max(fwidth(p.x), fwidth(p.y));          // taille d'un pixel en mètres sur la surface
	float hb = h21(id + vec2(7.0, 3.0));
	float hb2 = h21(id + vec2(1.3, 9.1));
	// --- teinte de l'élément
	vec3 c = mix(couleur.rgb, couleur2.rgb, step(1.0 - part2, hb2));
	c *= 1.0 + var_teinte * (hb * 2.0 - 1.0);
	c *= vec3(1.0 + 0.04 * (h21(id + 2.2) - 0.5), 1.0, 1.0 - 0.05 * (h21(id + 5.5) - 0.5));
	// variation à l'intérieur de l'élément (nuages doux), grain facultatif
	vec2 pl = loc + vec2(hb * 13.0, hb2 * 7.0);
	float nn = fnoise(pl * 3.1, fw * 3.1) * 0.6 + fnoise(pl * 9.3, fw * 9.3) * 0.4;
	if (motif == 2) {
		// fil du bois : bruit étiré le long de la lame
		nn = fnoise(vec2(pl.x * 0.9, pl.y * 26.0), fw * 26.0) * 0.7 + fnoise(pl * 4.0, fw * 4.0) * 0.3;
	}
	c *= 0.88 + 0.24 * nn;
	if (motif == 0) {
		// modelé peint : chaque pierre plus claire en haut, plus sombre en bas (lecture des assises)
		c *= 1.0 - modele + 2.0 * modele * smoothstep(0.0, 1.0, loc.y / taille.y);
	}
	if (grain_k > 0.0) {
		vec3 g = texture(grain, (loc + vec2(hb, hb2) * 5.0) / grain_m).rgb;
		float lg = dot(g, vec3(0.3, 0.55, 0.15));
		c *= 1.0 + grain_k * (lg - 0.45) * 1.6;
	}
	// --- arêtes : biseau éclairci (usure) ou épaufrures assombries
	float ep = biseau * (0.6 + 0.8 * fnoise(p * 5.0 + hb * 9.0, fw * 5.0));
	float arete = 1.0 - smoothstep(joint, joint + ep, d);
	c = mix(c, c * (1.0 - 0.22 * usure), arete * 0.7);
	// --- dallage : polissage au centre des dalles, plaques plus sombres
	if (motif == 1) {
		c *= 1.0 + 0.08 * usure * smoothstep(0.1, 0.35, d);
		c = mix(c, c * vec3(0.86, 0.84, 0.82), smoothstep(0.62, 0.9, fnoise(wpos.xz * 0.35, fw * 0.35)) * 0.6);
	}
	// --- tuiles : canal (bombé) et ombre portée du rang supérieur
	float bombe = 0.0;
	if (motif == 3) {
		float u = loc.x / taille.x;
		bombe = sin(u * PI);
		c *= 0.78 + 0.3 * bombe;
		c *= mix(0.68, 1.0, smoothstep(0.0, 0.07, loc.y));          // pied de la tuile du dessus
	}
	// --- joint filtré : sa couverture moyenne remplace le trait quand il devient sous-pixel
	float jw = joint;
	float aa = max(fw * 0.75, 1e-4);
	float jm = 1.0 - smoothstep(jw - aa, jw + aa, d);
	jm *= clamp(jw / aa, 0.25, 1.0);                     // trait plus fin que le pixel : contraste réduit
	if (motif != 3) {
		vec3 cj = c_joint.rgb * (0.9 + 0.2 * fnoise(p * 7.0, fw * 7.0));
		c = mix(c, cj, jm);
	} else {
		c = mix(c, c * 0.55, jm);
	}
	// --- vieillissement en hauteur (monde) : pied sali et verdi, coulures sous les arêtes hautes
	vec2 wp = wpos.xz + vec2(wpos.y * 0.7, 0.0);
	if (abs(wnrm.y) < 0.5) {
		float y = wpos.y - base_y;
		float pied = 1.0 - smoothstep(0.0, 0.9, y);
		c *= 1.0 - salissure * pied * (0.7 + 0.3 * fnoise(wp * 1.3, fw));
		c = mix(c, c * vec3(0.82, 0.95, 0.74), mousse * pied * smoothstep(0.35, 0.8, fnoise(wp * 0.8 + 4.0, fw)));
		float tr = fnoise(vec2((wpos.x + wpos.z) * 2.3, wpos.y * 0.22), fw * 2.3);
		c *= 1.0 - coulures * smoothstep(0.55, 0.95, tr) * smoothstep(0.2, 2.2, y) * 0.6;
	} else {
		// sols et dessus : verdissement des joints, grandes plaques plus sèches
		c = mix(c, c * vec3(0.78, 0.92, 0.72), mousse * jm * smoothstep(0.4, 0.8, fnoise(wp * 0.6, fw)));
	}
	// variation lente à l'échelle du bâtiment
	c *= 1.0 + 0.08 * (vnoise(wp * 0.07) * 2.0 - 1.0);
	c *= valeur;
	ALBEDO = c;
	ROUGHNESS = 1.0;
	// --- relief par dérivées d'écran (sans tangentes) : biseaux, joints creux, tuiles bombées ; s'éteint à distance
	float k_rel = relief * (1.0 - smoothstep(0.012, 0.05, fw));
	if (k_rel > 0.001) {
		float hgt = smoothstep(joint * 0.5, joint + ep, d) * 0.012 + nn * 0.004;
		if (motif == 3) { hgt = bombe * 0.03 - (1.0 - smoothstep(0.0, 0.06, loc.y)) * 0.01; }
		hgt *= k_rel;
		vec3 dpx = dFdx(VERTEX);
		vec3 dpy = dFdy(VERTEX);
		float dhx = dFdx(hgt);
		float dhy = dFdy(hgt);
		vec3 r1 = cross(dpy, NORMAL);
		vec3 r2 = cross(NORMAL, dpx);
		float det = dot(dpx, r1);
		if (abs(det) > 1e-9) {
			vec3 g = sign(det) * (dhx * r1 + dhy * r2);
			NORMAL = normalize(abs(det) * NORMAL - g * 0.9);
		}
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
