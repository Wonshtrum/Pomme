#version 150

#include "lib.glsl"

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform ivec2 atlasSize;

layout(triangles) in;
layout(triangle_strip, max_vertices = 9) out;

in VS_OUT {
    vec3 color;
    vec3 normal;
    vec4 tangent;
    vec2 uv_color;
    vec2 uv_light;
    vec3 bpos;
    int mc_id;
} gs_in[];

float D = EXTRUSION / 16.;

out vec3 v_normal;
out vec4 v_tangent;
flat out vec3 v_out_normal;
flat out int v_light_type;

out vec3 v_color;
out vec2 v_uv_color;
out vec2 v_uv_light;
out vec3 v_eye_pos;
out vec3 v_mid;
flat out int v_mc_id;

out float v_aspect;
out float v_z;
out vec2 v_min;
out vec2 v_max;

void main() {
    v_normal = gs_in[0].normal;
    v_out_normal = vec3(0, 0, 1);
    v_mc_id = gs_in[0].mc_id;
    v_mid = gl_in[0].gl_Position.xyz + gs_in[0].bpos;

    bool is_diag = abs(abs(dot(v_normal, vec3(1, 0, 0)))-0.5) < 0.4;
    bool is_back = dot(v_normal, vec3(1, 0, 2)) < 0;
    float flip = is_back && (has(v_mc_id, FLAG_FLIPPED) || is_diag && has(v_mc_id, FLAG_DIAG_FLIPPED)) ? -1 : 1;
    v_tangent = vec4(normalize(gs_in[0].tangent.xyz), sign(gs_in[0].tangent.w)) * flip;
    vec3 bitangent = cross(v_tangent.xyz, v_normal);

    if (has(v_mc_id, FLAG_FLAT_LIGHTING) || (is_diag && has(v_mc_id, FLAG_DIAG_LIGHTING))) {
        v_light_type = FLAG_FLAT_LIGHTING;
    } else if (has(v_mc_id, FLAG_DARK_LIGHTING)) {
        v_light_type = FLAG_DARK_LIGHTING;
    } else {
        v_light_type = 0;
    }

    vec2 v0 = fract(gs_in[0].uv_color * atlasSize / 16);
    vec2 v2 = fract(gs_in[2].uv_color * atlasSize / 16);
    v_min = 16 * (min(v0, v2) - 0.51);
    v_max = 16 * (max(v0, v2) - 0.51);
    float flip_base = flip > 0 ? 0 : gs_in[0].uv_color.x + gs_in[2].uv_color.x;

    vec3 p0 = gl_in[0].gl_Position.xyz;
    vec3 p1 = gl_in[1].gl_Position.xyz;
    vec3 p2 = gl_in[2].gl_Position.xyz;
    v_aspect = abs(dot(p0 - p2, v_tangent.xyz) * (v_max.y - v_min.y) / (dot(p0 - p2, bitangent) * (v_max.x - v_min.x)));

    mat4 mvp = projectionMatrix * modelViewMatrix;
    vec4 pos;
    vec3 normal;
    for (int i = 0; i < 3; i++) {
        v_color = gs_in[i].color;
        v_uv_color = vec2(flip_base + flip * gs_in[i].uv_color.x, gs_in[i].uv_color.y);
        v_uv_light = gs_in[i].uv_light;

        normal = v_normal * D;
        pos = gl_in[i].gl_Position + vec4(normal, 0);
        gl_Position = mvp * pos;
        v_eye_pos = pos.xyz;
        v_z = D;
        EmitVertex();
    }
    EndPrimitive();

    vec2 out_normal_1 = normalize(vec2(dot(p1 - p0, v_tangent.xyz), dot(p1 - p0, bitangent * v_tangent.w)));
    vec2 out_normal_2 = normalize(vec2(dot(p1 - p2, v_tangent.xyz), dot(p1 - p2, bitangent * v_tangent.w)));
    for (int i = 0; i < 3; i++) {
        v_color = gs_in[i].color;
        v_uv_color = vec2(flip_base + flip * gs_in[i].uv_color.x, gs_in[i].uv_color.y);
        v_uv_light = gs_in[i].uv_light;
        normal = gs_in[i].normal * D;
        v_out_normal = i == 2 ? vec3(out_normal_1, 0) : vec3(out_normal_2, 0);

        pos = gl_in[i].gl_Position + vec4(normal, 0);
        gl_Position = mvp * pos;
        v_eye_pos = pos.xyz;
        v_z = D;
        EmitVertex();

        pos = gl_in[i].gl_Position;
        gl_Position = mvp * pos;
        v_eye_pos = pos.xyz;
        v_z = 0;
        EmitVertex();
    }
    EndPrimitive();
}