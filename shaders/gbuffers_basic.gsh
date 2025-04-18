#version 150

#include "lib.glsl"

uniform sampler2D gtexture;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform int renderStage;

layout(triangles) in;
layout(triangle_strip, max_vertices = 12) out;

in VS_OUT {
    vec3 color;
    vec3 normal;
    vec4 tangent;
    vec2 uv_color;
    vec2 uv_light;
    vec3 bpos;
    int mc_id;
} gs_in[];

out vec3 v_normal;
out vec4 v_tangent;
flat out vec3 v_out_normal;

out vec3 v_color;
out vec2 v_uv_color;
out vec2 v_uv_light;
out vec3 v_eye_pos;
out vec3 v_mid;
out float v_z;

flat out ivec2 v_texture_size;
flat out ivec2 v_min;
flat out ivec2 v_max;
flat out ivec2 v_span;
out float v_factor;
out float v_aspect;

flat out int v_light_type;
flat out int v_mc_id;

void main() {
    if (renderStage == MC_RENDER_STAGE_PARTICLES) {
        mat4 mvp = projectionMatrix * modelViewMatrix;
        for (int i = 0; i < 3; i++) {
            v_color = gs_in[i].color;
            v_uv_color = gs_in[i].uv_color;
            v_uv_light = gs_in[i].uv_light;

            vec4 pos = mvp * gl_in[i].gl_Position;
            v_z = pos.z / pos.w;
            gl_Position = pos;
            EmitVertex();
        }
        EndPrimitive();
        return;
    }

    v_texture_size = textureSize(gtexture, 0);
    v_mc_id = gs_in[0].mc_id;
    v_mid = gl_in[0].gl_Position.xyz + gs_in[0].bpos;
    v_normal = gs_in[0].normal;
    v_out_normal = UP;

    bool is_diag = abs(abs(dot(v_normal, vec3(1, 0, 0)))-0.5) < 0.4;
    bool is_back = dot(v_normal, vec3(1, 0, 2)) < 0;
    float flip = is_back && (has(v_mc_id, FLAG_FLIPPED) || is_diag && has(v_mc_id, FLAG_DIAG_FLIPPED)) ? -1 : 1;
    float flip_base = flip > 0 ? 0 : gs_in[0].uv_color.x + gs_in[2].uv_color.x;
    v_tangent = vec4(normalize(gs_in[0].tangent.xyz), sign(gs_in[0].tangent.w)) * flip;
    vec3 bitangent = cross(v_tangent.xyz, v_normal);

    if (has(v_mc_id, FLAG_FLAT_LIGHTING) || (is_diag && has(v_mc_id, FLAG_DIAG_LIGHTING))) {
        v_light_type = FLAG_FLAT_LIGHTING;
    } else if (has(v_mc_id, FLAG_DARK_LIGHTING)) {
        v_light_type = FLAG_DARK_LIGHTING;
    } else {
        v_light_type = 0;
    }

    vec2 v0 = gs_in[0].uv_color * v_texture_size;
    vec2 v1 = gs_in[1].uv_color * v_texture_size;
    vec2 v2 = gs_in[2].uv_color * v_texture_size;
    v_min = ivec2(round(min(min(v0, v1), v2)));
    v_max = ivec2(round(max(max(v0, v1), v2)));
    v_span = v_max - v_min;

    vec3 p0 = gl_in[0].gl_Position.xyz;
    vec3 p1 = gl_in[1].gl_Position.xyz;
    vec3 p2 = gl_in[2].gl_Position.xyz;
    vec3 diag = p0 - p2;

    vec2 axes = abs(vec2(dot(diag, v_tangent.xyz), dot(diag, bitangent)));
    vec2 pixel = axes / v_span;
    float depth = EXTRUSION * pixel.y;
    v_factor = length(vec3(pixel, depth)) / length(vec3(1));
    v_aspect = pixel.x / pixel.y;
    if (v_aspect > 2 || v_aspect < 0.01) return;

    mat4 mvp = projectionMatrix * modelViewMatrix;
    vec4 normal = vec4(depth * v_normal, 0);
    vec4 pos;
    for (int i = 0; i < 3; i++) {
        v_color = gs_in[i].color;
        v_uv_color = vec2(flip_base + flip * gs_in[i].uv_color.x, gs_in[i].uv_color.y);
        v_uv_light = gs_in[i].uv_light;

        v_z = EXTRUSION;
        pos = gl_in[i].gl_Position + normal;
        gl_Position = mvp * pos;
        v_eye_pos = pos.xyz;
        EmitVertex();
    }
    EndPrimitive();

#ifdef ENTITY_STAGE
    for (int i = 0; i < 3; i++) {
        v_color = gs_in[i].color;
        v_uv_color = vec2(flip_base + flip * gs_in[i].uv_color.x, gs_in[i].uv_color.y);
        v_uv_light = gs_in[i].uv_light;

        v_z = -EXTRUSION;
        pos = gl_in[i].gl_Position - normal;
        gl_Position = mvp * pos;
        v_eye_pos = pos.xyz;
        EmitVertex();
    }
    EndPrimitive();
#endif

    vec2 out_normal_1 = normalize(vec2(dot(p1 - p0, v_tangent.xyz), dot(p1 - p0, bitangent * v_tangent.w)));
    vec2 out_normal_2 = normalize(vec2(dot(p1 - p2, v_tangent.xyz), dot(p1 - p2, bitangent * v_tangent.w)));
    for (int i = 0; i < 3; i++) {
        v_color = gs_in[i].color;
        v_uv_color = vec2(flip_base + flip * gs_in[i].uv_color.x, gs_in[i].uv_color.y);
        v_uv_light = gs_in[i].uv_light;
        v_out_normal = i == 2 ? vec3(out_normal_1, 0) : vec3(out_normal_2, 0);

        v_z = EXTRUSION;
        pos = gl_in[i].gl_Position + normal;
        gl_Position = mvp * pos;
        v_eye_pos = pos.xyz;
        EmitVertex();

#ifdef ENTITY_STAGE
        v_z = -EXTRUSION;
        pos = gl_in[i].gl_Position - normal;
#else
        v_z = 0;
        pos = gl_in[i].gl_Position;
#endif
        gl_Position = mvp * pos;
        v_eye_pos = pos.xyz;
        EmitVertex();
    }
    EndPrimitive();
}