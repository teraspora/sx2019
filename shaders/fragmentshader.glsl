precision mediump float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

varying vec3 fragColour;

vec3 col;

// Some functions adapted from Github - 
// https://github.com/tobspr/GLSL-Color-Spaces/blob/master/ColorSpaces.inc.glsl

// Converts a value from linear RGB to HCV (Hue, Chroma, Value)
vec3 rgb2hcv(vec3 rgb) {
    // Based on work by Sam Hocevar and Emil Persson
    vec4 P = (rgb.g < rgb.b) ? vec4(rgb.bg, -1.0, 2.0/3.0) : vec4(rgb.gb, 0.0, -1.0/3.0);
    vec4 Q = (rgb.r < P.x) ? vec4(P.xyw, rgb.r) : vec4(rgb.r, P.yzx);
    float C = Q.x - min(Q.w, Q.y);
    float H = abs((Q.w - Q.y) / (6. * C + 1.e-10) + Q.z);
    return vec3(H, C, Q.x);
}

// My inline library of useful functions:

float arg(vec2 z) {
    return atan(z.y, z.x);
}

vec2 polar(float r, float phi) {
    return vec2(r * cos(phi), r * sin(phi));
}

vec2 times(vec2 v, vec2 w) {
    return vec2(v.x * w.x - v.y * w.y, v.x * w.y + v.y * w.x);
}

vec2 rotate(vec2 v, float phi) {
    return times(v, polar(1.0, phi)) ;
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

vec3 invert(vec3 col) {
    return 1. - clamp(col, 0., 1.);   
}

float minkd(vec2 u, vec2 v, float order) {  // Minkowski distance order 1
    if (order <= 0.) return 0.;             // i.e. Manhattan distance
    return abs(pow(abs(pow(v.x - u.x, order)) + abs(pow(v.y - u.y, order)), 1. / order)); 
}

// rand generator from 
// https://www.youtube.com/watch?v=l-07BXzNdPw&t=740s
vec2 r22(vec2 p) {
    vec3 a = fract(p.xyx * vec3(923.34, 234.34, 345.65));
    a += dot(a, a - 34.45);
    return fract(vec2(a.x * a.y, a.y * a.z));
}


// float f(float x) {
//     return sin(cos(0.2 * u_time * x)) + cos(2. * sin(0.23 * u_time * x)) - sqrt(0.2 *abs(x) * cos(0.02 * u_time * x));
// }

void main() {
    float t = u_time / 3.;
    vec2 mouseFactor = pow(vec2(2.0), u_mouse * 3.0);
    float scale = 0.5 * mouseFactor.x;
    
    if (t < 24.) scale += 0.1 * sin(t);
    
    float asp = u_resolution.x / u_resolution.y;
    // Normalized pixel coordinates (y from -1 to 1)
    vec2 uv = (2. * gl_FragCoord.xy - u_resolution.xy) / (u_resolution.y * scale);
        
    uv = abs(uv);
    float temp = uv.y;
    uv.y += sin(uv.x + t);
    uv.x += cos(temp + t);

    float mind = 100.;
    float ci;
    
    // generate a bunch of random points
    for (float i = 0.; i < 4.; i++) {
        vec2 n = r22(vec2(i));
        // sin of both components varied with time
        vec2 p = sin(n * t);
        // get distance to point
        float d = minkd(uv, p, 1.);
        if (d < mind) {
            mind = d;
            ci = i;
        }
    }
    
    col = invert(vec3(mind));
    col.g -= nsin(t + length(uv));
    col.b += 0.5 * smoothstep(0., 1., col.r + col.b);
    
    if (rgb2hcv(col).z < 0.01) col = 0.5 + 0.5 * cos(t + uv.xyx + vec3(27.0, 49.0, 81.0));    
    
    gl_FragColor = vec4(col, 1.);
}