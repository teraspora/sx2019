#define PI 3.1415922653589793234
#define PHI 1.6180339887 
#define SQ2 1.4142135623
/*
Shader: Onducelli
Author: John Lynch
Date: July 2019
*/

precision mediump float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform int u_colshift;

varying vec3 fragColour;

float a = 1.9;
float order = 1.;

vec3 black = vec3(0.);
vec3 white = vec3(1.);
vec3 orange = vec3(1., 0.8, 0.1);
vec3 dark_blue = vec3(0.01, 0.0, 0.2);

vec3 colour1 = vec3(.9, .3, .2);
vec3 colour2 = vec3(.0, .7, .8);
vec3 colour3 = vec3(.8, .5, .1);
vec3 colour4 = vec3(.8, .3, .7);

float minkd(vec2 u, vec2 v, float order) {
    if (order <= 0.) return 0.;       
    return abs(pow(abs(pow(v.x - u.x, order)) + abs(pow(v.y - u.y, order)), 1. / order)); 
}

float minkl(vec2 v, float order) {
    if (order <= 0.) return 0.;
    return abs(pow(abs(pow(v.x, order)) + abs(pow(v.y, order)), 1. / order)); 
}

vec2 nmouse() {
   return u_mouse.xy;
}

// Gold Noise ©2015 dcerisano@standard3d.com
float gold_noise(in vec2 coord, in float seed) {
    return fract(tan(distance(coord * (seed + PHI), vec2(PHI, PI))) * SQ2);
}

vec2 gn2(in vec2 v, in float seed) {
    return vec2(gold_noise(v, seed), gold_noise(v.yx, seed));
}

// Some functions adapted from Github - 
// https://github.com/tobspr/GLSL-Color-Spaces/blob/master/ColorSpaces.inc.glsl
vec3 hue2rgb(float hue)
{
    float R = abs(hue * 6. - 3.) - 1.;
    float G = 2. - abs(hue * 6. - 2.);
    float B = 2. - abs(hue * 6. - 4.);
    return clamp(vec3(R,G,B), 0., 1.);
}

// Converts a value from linear RGB to HCV (Hue, Chroma, Value)
vec3 rgb2hcv(vec3 rgb) {
    // Based on work by Sam Hocevar and Emil Persson
    vec4 P = (rgb.g < rgb.b) ? vec4(rgb.bg, -1.0, 2.0/3.0) : vec4(rgb.gb, 0.0, -1.0/3.0);
    vec4 Q = (rgb.r < P.x) ? vec4(P.xyw, rgb.r) : vec4(rgb.r, P.yzx);
    float C = Q.x - min(Q.w, Q.y);
    float H = abs((Q.w - Q.y) / (6. * C + 1.e-10) + Q.z);
    return vec3(H, C, Q.x);
}

// Converts from HSL to linear RGB
vec3 hsl2rgb(vec3 hsl) {
    vec3 rgb = hue2rgb(hsl.x);
    float C = (1. - abs(2. * hsl.z - 1.)) * hsl.y;
    return (rgb - 0.5) * C + hsl.z;
}

// Converts from linear rgb to HSL
vec3 rgb2hsl(vec3 rgb) {
    vec3 HCV = rgb2hcv(rgb);
    float L = HCV.z - HCV.y * 0.5;
    float S = HCV.y / (1. - abs(L * 2. - 1.) + 1.e-10);
    return vec3(HCV.x, S, L);
}

// Colour fns.:
float hue(vec3 col) {
    return rgb2hsl(col).s;
}

vec3 changeHue(vec3 col, float newHue) {
    vec3 colHSL = rgb2hsl(col);
    colHSL.s = newHue;
    return hsl2rgb(colHSL);
}
    
float lightness(vec3 col) {
    return rgb2hsl(col).b;
}

vec3 changeLightness(vec3 col, float newLightness) {
    vec3 colHSL = rgb2hsl(col);
    colHSL.p = newLightness;
    return hsl2rgb(colHSL);
}
    
vec3 saturate(vec3 col) {
    vec3 colHSL = rgb2hsl(col);
    colHSL.t = 1.0;
    return hsl2rgb(colHSL);    
}

// vec2 nmouse() {
//    return iMouse.xy / iResolution.xy;
// }

float om(float x) {     // one minus x
    return 1. - x;
}

vec3 om(vec3 v) {       // one minus v
    return 1. - v;
}

float op(float x) {     // one plus x 
    return 1. + x;
}

// Normalised trig fns.:
float nsin(float x) {
    return op(sin(x)) * 0.5;
}

float ncos(float x) {
    return op(cos(x)) * 0.5;
}

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

vec2 trt(vec2 v, vec2 offset, float phi) {
    return rotate(v - offset, phi) + offset;
}

float sec(float theta) {
    return 1. / cos(theta);
}

float iden(float x) {
    return x;
}

float discus(vec2 v, float offset, float r) {
    vec2 voff = vec2(0.0, offset); 
    float d = step(minkl(v - voff, order), r) * step(minkl(v + voff, order), r) * step(minkl(v - voff - 0.06, order), r) * step(minkl(v + voff + 0.06, order), r);
    return d;
}

float bird(vec2 v) {
    return discus(v + vec2(0.25, 0.0), 0.3, 0.4) + discus(v - vec2(0.25, 0.0), 0.3, 0.4) + step(minkl(v, order), 0.09) 
     - step(minkl(v, order), 0.02);
}

float yawingBird(vec2 v, float phi) {
    return bird(rotate(v, phi));
} 

// from IQ:
vec2 rand2( vec2 p ) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

float borderRadius(vec2 v, vec2 res, float size) {
    // Multiply this by the colour; note, uses global vars/uniforms; could modify to take a general vector and resolution as args.
    float p = 1. - step(v.x, size) * step(v.y, size) * step(size, distance(v.xy, vec2(size)));
    vec2 u = vec2(v.x, res.y - v.y);
    p *= 1. - step(u.x, size) * step(u.y, size) * step(size, distance(u.xy, vec2(size)));
    u = vec2(res.x - v.x, v.y);
    p *= 1. - step(u.x, size) * step(u.y, size) * step(size, distance(u.xy, vec2(size)));
    u = vec2(res.x - v.x, res.y - v.y);
    p *= 1. - step(u.x, size) * step(u.y, size) * step(size, distance(u.xy, vec2(size)));
    return p;
}

void main() {
    float t = u_time / 7.;
    float a = 1.9;
    float phi = t;

    float scale = .4;
    vec3 col;
    vec2 asp = vec2(u_resolution.x / u_resolution.y, 1.);
    vec2 uv = gl_FragCoord.xy / u_resolution.yy - asp * .5;
    float amp = 0.04;
    float freq = 5.;
    float freqx = floor(3. + 32. * nsin(t / 24.)); 
    uv /= scale;
    uv.y = -uv.y;
    float uvy = uv.y;
    // make waves
    uv.y += nmouse().y * cos(16. * (uv.x + 0.1 * sin(t / 5.)))  + 0.04 * cos(12. * uv.x);
    uv.x += nmouse().y * cos(16. * uvy)   + 0.02 * cos(12. * uvy);    

    col = mix(vec3(.2, .9, .6), vec3(.9, .3, .2), nsin(pow(minkl(uv, order), exp2(1. * nsin(t / 4.) * minkl(uv, order))))) / 2.;
    float cdelta = mod(t, 15.) / 15.;
    col = changeHue(col, fract(hue(col) + cdelta)); 
    
    float birds = 0.4 + nmouse().x;
    for (int i = 0; i < 6; i++) {   // make 6 birds with differing orbits
        vec2 offset = gn2(vec2(float(i) * 91., 1049. / (float(i) + 100.)), float(float(i) * 103.61)) * asp - asp / 2.;
        if (mod(float(i), 2.) < .5) {
            offset += vec2(sin(t  / 2. * (float(i) + 1.)), cos(t / 3. * (float(i) + 1.)));      // Ellipse[-ish]
        }
        else if (mod(float(i), 3.) < 0.5) {
            offset = vec2(polar(a * sin(2. * phi), phi)) * asp * 0.67 * nsin(mod(t / 8., 240.));     // Quadrifolium
        }
        else if (mod(float(i), 5.) < 0.5) {
            offset = 0.5 * vec2(3. * cos(phi) - cos(3. * phi), 3. * sin(phi) + sin(3. * phi)) * asp * 0.67 * nsin(mod(t / 2., 240.));     // Astroid
        }
        else {
            offset = clamp(vec2(a * sin(phi), a * sin(phi) * cos(phi)) * asp * 0.75 * nsin(mod(t / 24., 640.)), vec2(0.1), vec2(2.0));     // Gerono lemniscate
        }

        float yb = yawingBird(uv + offset, clamp(4. * rand2(vec2(float(i) * 37., 2051. / (float(i) + 89.))).x * nsin(t * float(i) * 2.), 0.4, 2.));
        
        birds += yb;
    }
    col *= birds * 3.;
    
    if (length(col) < .9) {
        col = dark_blue;    // night sky
        // waves, vegetation etc.
        if (uv.y > .1 + 0.06 * sin((t + mod((uv.x + sin(t / 5.)) * 6. , 0.4)) * 5.) && uv.y < 1.2 + 0.23 * sin((t / 4. + mod(uv.x * 9. , 0.2)) * 7.)) 
            col = mix(orange, dark_blue, (uv.y - .2 + 0.01 * sin(t / 5. * uv.x)) * 1.);
    }
    cdelta = mod(t, 9.1) / 9.1;
    if (col != dark_blue) col = changeHue(col, fract(hue(col) + cdelta)); 
    col *= 1.;
    if (length(col) > 1.25) col = 0.5 + 0.5 * cos(u_time + uv.yxy + vec3(2, 0,4));
    col = saturate(col);
    col *= borderRadius(gl_FragCoord.xy, u_resolution.xy, length(u_resolution.xy) * 0.166);
    if (u_colshift == 1) {
        col = col.gbr;
    }
    else if (u_colshift == 2) {
        col = col.brg;
    }
    gl_FragColor = vec4(col,1.0);
}  
