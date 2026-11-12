// P4 — rivière animée. Dérivé de EAU-01_flow_plane_3d.gdshader (pack P4_PILOTES_TECH_v01) : défilement continu de
// la texture EAU-01 avec TIME, ondulation et reflets ; ajouts : hauts-fonds EAU-02 près des rives, liseré d'écume.
shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
uniform sampler2D water_albedo : source_color, repeat_enable, filter_linear_mipmap;   // EAU-01 (courant)
uniform sampler2D shallow_albedo : source_color, repeat_enable, filter_linear_mipmap; // EAU-02 (galets)
uniform vec2 flow_direction = vec2(0.0, 0.06);    // UV/s
uniform float wave_strength = 0.006;
uniform float glint_strength = 0.09;
uniform float tile_m = 7.0;
uniform float bank_x0 = 0.0;
uniform float bank_x1 = 4.0;
uniform float anim = 1.0;
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float t = TIME * anim;
	vec2 base_uv = wpos.xz / tile_m;
	vec2 uv = base_uv - flow_direction * t;
	float wave = sin(base_uv.y * 19.0 + t * 1.1) * cos(base_uv.x * 13.0 - t * 0.72);
	uv += wave_strength * vec2(wave, -wave * 0.6);
	vec3 deep = texture(water_albedo, uv).rgb;
	vec3 shal = texture(shallow_albedo, uv * 1.25 + vec2(0.37, 0.0)).rgb;
	float edge = min(wpos.x - bank_x0, bank_x1 - wpos.x);
	float n = sin(wpos.z * 1.7 + sin(wpos.z * 0.6) * 2.0) * 0.18;
	vec3 base = mix(shal, deep, smoothstep(0.15, 1.35, edge + n));
	float glint = 0.5 + 0.5 * sin(uv.x * 43.0 + uv.y * 27.0 + t * 1.8);
	base += vec3(0.25, 0.45, 0.6) * glint_strength * glint * glint * dot(base, vec3(0.5));
	float foam = smoothstep(0.34, 0.05, edge + n * 0.6) * (0.55 + 0.45 * sin(wpos.z * 5.0 - t * 2.2 + sin(wpos.x * 9.0)));
	base = mix(base, vec3(0.86, 0.93, 0.97), clamp(foam, 0.0, 1.0) * 0.55);
	base = mix(base, vec3(dot(base, vec3(0.3, 0.5, 0.2))), 0.22);
	ALBEDO = base * vec3(0.78, 0.84, 0.9);
	EMISSION = base * 0.04;
	ROUGHNESS = 0.4;
}
