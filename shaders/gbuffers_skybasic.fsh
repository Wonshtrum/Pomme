#version 150

#include "lib.glsl"

// DRAWBUFFERS:0
layout(location = 0) out vec4 outColor;

in vec4 v_color;

void main() {
    outColor = v_color;
}
