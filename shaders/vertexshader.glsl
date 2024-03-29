precision mediump float;

uniform float u_time;
uniform vec2 u_resolution;

attribute vec2 vertPosition;
attribute vec3 vertColour;


varying vec3 fragColour;

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

void main() {
    fragColour = vertColour;
    // gl_Position = vec4(rotate(vertPosition, u_time), 0.0, 1.0);
    gl_Position = vec4(vertPosition, 0.0, 1.0);
}
