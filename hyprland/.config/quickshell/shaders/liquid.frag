#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    vec2  size;     // window size in px
    vec4  color;    // bar color
    float cx;       // blob center x
    float ext;      // how far the liquid sticks out below the bar (px)
    float boxW;     // blob width (px)
    float radius;   // bottom corner radius
    float k;        // smoothing amount = fillet size
};

float smin(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * k * 0.25;
}

float sdRoundBox(vec2 p, vec2 hs, float r) {
    vec2 q = abs(p) - hs + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
    vec2 p = qt_TexCoord0 * size;

    // the bar: everything above y=1 is solid (negative = inside)
    float dSurface = p.y - 1.0;

    // the liquid: a box that starts hidden inside the bar and grows downward
    float overlap = 60.0;
    vec2 c  = vec2(cx, (ext - overlap) * 0.5);
    vec2 hs = vec2(boxW * 0.5, (ext + overlap) * 0.5);
    float dBox = sdRoundBox(p - c, hs, min(radius, min(hs.x, ext * 0.5)));

    // smooth union: k is the fillet
    float d = smin(dSurface, dBox, max(k, 0.001));

    float aa = max(fwidth(d), 0.0001);
    float a = 1.0 - smoothstep(-aa, aa, d);
    fragColor = color * (a * qt_Opacity);
}2