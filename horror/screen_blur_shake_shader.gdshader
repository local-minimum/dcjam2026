shader_type canvas_item;

uniform vec2 blur_center = vec2(0.5, 0.5);
uniform float base_blur_power : hint_range(0.0, 1.0) = 0.01;
uniform float pulse_frequency : hint_range(0.1, 10.0) = 0.1;
uniform float pulse_amplitude : hint_range(0.0, 10.0) = 0.1; // Adjust as needed
uniform float darkening_amplitude : hint_range(0.0, 1.0) = 0.01; // Adjust as needed
uniform float lightening_amplitude : hint_range(0.0, 1.0) = 0.01; // Adjust as needed

uniform int sampling_count : hint_range(1, 64) = 6;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec2 direction = SCREEN_UV - blur_center;
    vec3 c = vec3(0.0, 0.0, 0.0);
    float f = 1.0 / float(sampling_count);
    
    // Calculate blur power with a pulsating effect
    float time_factor = sin(TIME * pulse_frequency) * pulse_amplitude + 1.0;
    float blur_power = base_blur_power * time_factor;
    
    // Calculate darkening effect with a pulsating effect
    float darkening_factor = sin(TIME * pulse_frequency * 0.5) * darkening_amplitude;
    
    // Calculate lightening effect with a pulsating effect
    float lightening_factor = sin(TIME * pulse_frequency * 0.7) * lightening_amplitude;
    
    // Combine darkening and lightening effects
    vec3 final_color = vec3(1.0) - darkening_factor + lightening_factor;
    
    for(int i = 0; i < sampling_count; i++) {
        c += texture(SCREEN_TEXTURE, SCREEN_UV - blur_power * direction * float(i)).rgb * f;
    }
    
    // Apply the combined color and blur effect
    COLOR.rgb = c * final_color;
}
