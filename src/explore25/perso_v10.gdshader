// P4.9 V10 — rendu des personnages de la forêt (proposition, touche K) : même dessin, rendu plus lisible.
//  - échantillonnage : en réduction (texel plus petit qu'un pixel d'écran, ex. Aren 96 × 112 affiché ×0,719 au
//    zoom ×3), moyenne de 4 points sur l'empreinte du pixel d'écran au lieu du « nearest » qui saute des rangées et
//    des colonnes (visage, contours abîmés, scintillement en marche) ; en agrandissement, « pixel net » (bords francs,
//    comme src/p4/perso_p41.gdshader) ;
//  - lumière : le soleil éclaire le sprite en entier, au lieu d'un éclairage de face rasant qui le ternit ; à l'ombre
//    des arbres il garde 45 % du soleil (assombri mais lisible, pas une silhouette noire) ; ambiance inchangée ;
//  - pas de brume sur le sprite (la brume de distance et le volumétrique le délavaient à 20 m de la caméra) ;
//  - contour fin (1 pixel d'écran) autour de la silhouette, pour la détacher du sol.
// Aucun pixel du dessin n'est modifié ; billboard identique au Sprite3D (orienté vers la caméra principale).
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, fog_disabled, specular_disabled;
uniform sampler2D tex : source_color, filter_linear, repeat_disable;
uniform float soleil = 0.62;          // part de la lumière directe (LIGHT_COLOR inclut énergie × PI)
uniform float ombre = 0.45;           // dans l'ombre portée : part du soleil gardée (assombri mais lisible)
uniform float contour = 1.0;          // 0 : sans contour
uniform vec4 couleur_contour : source_color = vec4(0.09, 0.07, 0.07, 1.0);
uniform float saturation = 1.06;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(MAIN_CAM_INV_VIEW_MATRIX[0], MAIN_CAM_INV_VIEW_MATRIX[1],
		MAIN_CAM_INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

vec4 echantillon(vec2 uv, vec2 sz, vec2 fw) {
	vec2 px = uv * sz;
	if (max(fw.x, fw.y) > 1.0) {
		// réduction : moyenne sur l'empreinte (alpha prémultiplié)
		vec4 s = vec4(0.0);
		for (int i = 0; i < 2; i++) {
			for (int j = 0; j < 2; j++) {
				vec2 o = (vec2(float(i), float(j)) - 0.5) * 0.5 * fw;
				vec4 t = texture(tex, (px + o) / sz);
				s += vec4(t.rgb * t.a, t.a);
			}
		}
		s *= 0.25;
		return vec4(s.a > 0.0 ? s.rgb / s.a : vec3(0.0), s.a);
	}
	vec2 seam = floor(px + 0.5);
	vec2 sp = seam + clamp((px - seam) / max(fw, vec2(1e-4)), -0.5, 0.5);
	return texture(tex, sp / sz);
}

void fragment() {
	vec2 sz = vec2(textureSize(tex, 0));
	vec2 fw = max(fwidth(UV * sz), vec2(1e-4));
	vec4 c = echantillon(UV, sz, fw);
	float a = step(0.5, c.a);
	vec3 rgb = c.rgb;
	if (a < 0.5 && contour > 0.5) {
		// pixel vide : contour si un voisin à un pixel d'écran est opaque
		vec2 d = fw / sz;
		float v = 0.0;
		v = max(v, texture(tex, UV + vec2(d.x, 0.0)).a);
		v = max(v, texture(tex, UV - vec2(d.x, 0.0)).a);
		v = max(v, texture(tex, UV + vec2(0.0, d.y)).a);
		v = max(v, texture(tex, UV - vec2(0.0, d.y)).a);
		if (v > 0.5) {
			a = 1.0;
			rgb = couleur_contour.rgb;
		}
	}
	float l = dot(rgb, vec3(0.299, 0.587, 0.114));
	ALBEDO = clamp(mix(vec3(l), rgb, saturation), 0.0, 1.0);
	ALPHA = a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}

void light() {
	DIFFUSE_LIGHT += mix(vec3(ombre), vec3(1.0), ATTENUATION) * LIGHT_COLOR / PI * soleil;
}
