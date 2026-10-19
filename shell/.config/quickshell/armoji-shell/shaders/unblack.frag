#version 440
// Turns the terminal's pure-black background transparent so the panel's
// frosted glass shows through. Over black, a pixel's brightness IS its
// coverage, so alpha = max channel recovers antialiased text exactly
// (rgb is already premultiplied by that alpha).
// Rebuild: /usr/lib/qt6/bin/qsb --glsl "100es,120,150" --hlsl 50 --msl 12 -o unblack.frag.qsb unblack.frag
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
};
layout(binding = 1) uniform sampler2D source;

void main() {
    vec4 c = texture(source, qt_TexCoord0);
    float a = max(max(c.r, c.g), c.b);
    fragColor = vec4(c.rgb, a) * qt_Opacity;
}
