#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;
    vec4 color;
    float cx;
    float ext;
    float boxW;
    float radius;
    float k;
    float lean;
};

float roundUnion(float a, float b, float r) {
    vec2 u = max(vec2(r - a, r - b), vec2(0.0));
    return max(r, min(a, b)) - length(u);
}

float sdRoundBox(vec2 p, vec2 hs, float r) {
    vec2 q = abs(p) - hs + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
    vec2 p = qt_TexCoord0 *  size;

    float dSurface = p.y - 1.0;

    float overlap = 250.0;
    float cy = (ext - overlap) * 0.5;
    vec2 hs = vec2(boxW * 0.5, (ext + overlap) * 0.5);

    vec2 q = vec2(abs(p.x - cx) + lean * (p.y - ext), p.y - cy);
    float dBox = sdRoundBox(q, hs, min(radius, min(hs.x, hs.y))) * inversesqrt(1.0 + lean * lean);

    float d = roundUnion(dSurface, dBox, max(k, 0.001));

    float aa = max(fwidth(d), 0.0001);
    float a = 1.0 - smoothstep(-aa, aa, d);
    fragColor = color * (a * qt_Opacity);

}