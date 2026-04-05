shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color;
uniform sampler2D texture_emission : source_color, hint_default_black, filter_linear_mipmap, repeat_enable;
uniform vec4 emission : source_color;
uniform float emission_energy : hint_range(0.0, 1000.0, 0.01) = 300.0;

void fragment() {
    vec4 albedo_tex = texture(texture_emission, UV);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	EMISSION = (emission.rgb + albedo_tex.rgb) * emission_energy;
}
