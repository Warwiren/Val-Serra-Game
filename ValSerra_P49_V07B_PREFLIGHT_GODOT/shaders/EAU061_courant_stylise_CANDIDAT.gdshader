shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled, diffuse_burley, specular_schlick_ggx;

// P49 V06.1 : prototype de mouvement de l’eau. Aucune validation Godot 4.7.2 GPU.
uniform sampler2D bruit_eau : source_color, repeat_enable;
uniform vec3 teinte_fond : source_color = vec3(0.10, 0.31, 0.32);
uniform vec3 teinte_lumiere : source_color = vec3(0.27, 0.52, 0.49);
uniform float vitesse_courant : hint_range(0.0, 1.0) = 0.08;
uniform float opacite : hint_range(0.0, 1.0) = 0.82;
uniform float force_rides : hint_range(0.0, 0.2) = 0.06;

void fragment() {
    vec2 uv_a = UV * vec2(2.2, 1.5) + vec2(-TIME * vitesse_courant, TIME * vitesse_courant * 0.18);
    vec2 uv_b = UV * vec2(3.7, 2.2) + vec2(-TIME * vitesse_courant * 0.43, -TIME * vitesse_courant * 0.15);
    float n = (texture(bruit_eau, uv_a).r + texture(bruit_eau, uv_b).r) * 0.5;
    ALBEDO = mix(teinte_fond, teinte_lumiere, smoothstep(0.27, 0.75, n));
    ROUGHNESS = 0.21;
    SPECULAR = 0.58;
    METALLIC = 0.0;
    ALPHA = opacite + (n - 0.5) * force_rides;
}
