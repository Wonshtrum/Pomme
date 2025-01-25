#version 150

uniform sampler2D gtexture;
uniform sampler2D lightmap;

// DRAWBUFFERS:0
layout(location = 0) out vec4 outColor;

in vec3 v_color;
in vec2 v_uv_color;
in vec2 v_uv_light;

void main() {
    vec4 base = texture2D(gtexture, v_uv_color);
    if (base.a < 0.1) discard;

    vec3 light = texture2D(lightmap, v_uv_light).rgb;
    outColor = base * vec4(light.rgb * v_color, 1);
}