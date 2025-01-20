#version 460

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform ivec2 atlasSize;

layout(triangles) in;
layout(triangle_strip, max_vertices=9) out;

in VS_OUT {
    vec3 color;
    vec3 normal;
    vec4 tangent;
    vec2 uv_color;
    vec2 uv_light;
    vec3 bpos;
} gs_in[];

float D = 1./16.;

out vec3 v_color;
out vec3 v_normal;
out vec4 v_tangent;
out vec2 v_uv_color;
out vec2 v_uv_light;
out vec3 v_eye_pos;
out vec3 v_mid;

out float v_aspect;
out float v_z;
out vec2 v_min;
out vec2 v_max;

void main() {
    mat4 mvp = projectionMatrix * modelViewMatrix;
    vec4 pos;
    vec3 normal;

    vec2 v0 = fract(gs_in[0].uv_color * atlasSize/16);
    vec2 v2 = fract(gs_in[2].uv_color * atlasSize/16);
    v_min = min(v0, v2);
    v_max = max(v0, v2);

    v_normal = gs_in[0].normal;
    v_tangent = gs_in[0].tangent;
    v_mid = gl_in[0].gl_Position.xyz + gs_in[0].bpos;

    vec3 p0 = gl_in[0].gl_Position.xyz;
    vec3 p1 = gl_in[1].gl_Position.xyz;
    vec3 p2 = gl_in[2].gl_Position.xyz;
    v_aspect = abs(dot(p0-p2, v_tangent.xyz) * (v_max.y-v_min.y) / (dot(p0-p2, cross(v_tangent.xyz, v_normal)) * (v_max.x-v_min.x)));

    for (int i = 0; i<3; i++) {
        v_color = gs_in[i].color;
        v_uv_color = gs_in[i].uv_color;
        v_uv_light = gs_in[i].uv_light;

        normal = v_normal * D;
        pos = gl_in[i].gl_Position + vec4(normal, 0);
        gl_Position = mvp * pos;
        v_eye_pos = pos.xyz;
        v_z = D;
        EmitVertex();
    }
    EndPrimitive();

    for (int i = 0; i<3; i++) {
        v_color = gs_in[i].color;
        v_uv_color = gs_in[i].uv_color;
        v_uv_light = gs_in[i].uv_light;

        normal = gs_in[i].normal * D;
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