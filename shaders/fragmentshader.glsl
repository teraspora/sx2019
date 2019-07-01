precision mediump float;

uniform float u_time;
uniform vec2 u_resolution;

varying vec3 fragColour;

float arg(vec2 z) {
    return atan(z.y, z.x);
}

float om(float x) {
    return 1. - x;
}

vec3 om(vec3 v) {
    return 1. - v;
}

float op(float x) {
    return 1. + x;
}

float nsin(float x) {
    return op(sin(x)) * 0.5;
}

float ncos(float x) {
    return op(cos(x)) * 0.5;
}

void main() {
    vec3 col;
    float scale =  1.;
    float asp = u_resolution.x / u_resolution.y;
    // Normalized pixel coordinates (y from -1 to 1)
    vec2 uv = (2. * gl_FragCoord.xy - u_resolution.xy) / (u_resolution.y * scale);
    col = vec3(nsin(u_time), 0.0, 1.0);
    col *= step(length(uv), 0.6 + sin(u_time / 2.0 - abs(arg(uv * 6.0))) / 8.0);
    gl_FragColor = vec4(col, 1.0);
}
