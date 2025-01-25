#version 150

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform vec3 chunkOffset;

in vec3 vaPosition;
in vec3 vaNormal;
in vec4 vaColor;
in vec2 vaUV0;
in uvec2 vaUV2;
in vec3 mc_Entity;

out vec3 v_color;
out vec2 v_uv_color;
out vec2 v_uv_light;
out int v_mc_id;

void main() {
    float light = dot(vaNormal * vaNormal, vec3(0.6, 0.25 * vaNormal.y + 0.75, 0.8));
    v_color = light * vaColor.rgb;
    v_uv_color = vaUV0;
    v_uv_light = vaUV2 / 256.0 + 1. / 32.;
    v_mc_id = mc_Entity.x < 0 ? 0 : int(mc_Entity.x);
    gl_Position = projectionMatrix * modelViewMatrix * vec4(vaPosition + chunkOffset, 1);
}