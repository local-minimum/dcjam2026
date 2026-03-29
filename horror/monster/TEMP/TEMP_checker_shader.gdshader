// NOT RECOMMENDED FOR USE IN PRODUCTION - NOT OPTIMISED, OR EVEN GOOD...

shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color = vec4(0.6, 0.6, 0.6, 1.0);

varying vec3 position;
varying vec3 normal;

void vertex() {
    position = VERTEX;
    normal = NORMAL;
}

float square_antialiased(float coord, float dd) {
    coord += dd * 0.5;
    dd = max(dd, 0.0001);
    float invdd = 1.0 / dd;
    coord = mod(coord, 1.0);
    float c = min(coord * invdd, 0.5 - (coord - 0.5) / dd + 0.5);
    return clamp(c, 0.0, 1.0);
}

float sxor(float a, float b) {
    return abs(a - b);
}

float checkers(vec3 coord, vec3 ddxyz, vec3 tripCoeff) {
    vec3 filter = clamp(1.0 / ddxyz * 0.5 - 0.5, 0.0, 1.0);
    float cx = square_antialiased(coord.x, ddxyz.x);
    float cy = square_antialiased(coord.y, ddxyz.y);
    float cz = square_antialiased(coord.z, ddxyz.z);
    float c = sxor(cy * filter.y, cz * filter.z) * tripCoeff.x +
              sxor(cz * filter.z, cx * filter.x) * tripCoeff.y +
              sxor(cx * filter.x, cy * filter.y) * tripCoeff.z +
              1.0 - dot(filter, vec3(0.3333));
    return c;
}

void fragment() {
    vec3 coord = position * 4.0;
    vec3 ddxyz = fwidth(coord);
    vec3 trip_coeff = max((normal * normal * 2.0 - 0.5), 0.001);
    trip_coeff /= (trip_coeff.x + trip_coeff.y + trip_coeff.z);
    
    float checks = checkers(coord, ddxyz, trip_coeff);
    
    coord = position;
    ddxyz = fwidth(coord);
    float checkersL = 1.0 - checkers(coord, ddxyz, trip_coeff);
    
    checks = mix(checks, checkersL, 0.7);
    
    ALBEDO = mix(albedo.rgb * 0.5, ALBEDO, checks);
}
