#version 150

#include "lib.glsl"

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D normals;
uniform ivec2 atlasSize;
uniform mat4 projectionMatrix;
uniform mat4 modelViewMatrix;
uniform vec3 cameraPosition;

// DRAWBUFFERS:0
layout(location = 0) out vec4 outColor;

in vec3 v_normal;
in vec4 v_tangent;
flat in vec3 v_out_normal;
flat in int v_light_type;

in vec3 v_color;
in vec2 v_uv_color;
in vec2 v_uv_light;
in vec3 v_eye_pos;
in vec3 v_mid;
flat in int v_mc_id;

in float v_aspect;
in float v_z;
in vec2 v_min;
in vec2 v_max;

const vec3 UP = vec3(0, 0, 1);

mat3 tbnNormalTangent(vec3 normal, vec3 tangent) {
    vec3 bitangent = cross(normal, tangent);
    return mat3(tangent, bitangent, normal);
}

vec4 correctedSample(sampler2D sampler, vec2 uv) {
    return textureGrad(sampler, v_uv_color + uv / atlasSize, dFdx(v_uv_color), dFdy(v_uv_color));
}

bool inBound(vec3 p) {
    return p.z >= -2 && p.x < v_max.x && p.x >= v_min.x && p.y < v_max.y && p.y >= v_min.y;
}

struct Hit {
    vec3 pos;
    vec2 delta;
    float dist;
    vec3 side;
};
Hit DDA(vec3 ro, vec3 rd) {
    ro *= 16;
    vec3 p = ro;
    vec3 cell = floor(p);
    vec3 origin = cell;

    vec3 next_edge = vec3(greaterThan(rd, vec3(0)));
    vec3 steps = (next_edge - fract(p)) / rd;
    vec3 rd_step = abs(1 / rd);
    vec3 rd_sign = sign(rd);

    vec3 step_axis;
    float t = 0;
    for (int i = 0; i < 32; i++) {
        vec2 delta = (cell - origin).xy;
        vec4 albedo = correctedSample(gtexture, delta);
        float alpha = albedo.a;
        float depth = dot(albedo.rgb, vec3(0.3, 0.3, 0.4));
        //float depth = 4*correctedSample(normals, delta).a-3;
        if (abs(p.z) < depth && alpha > 0.1) {
            return Hit(p / 16, delta, t / 16, i == 0 ? mix(UP, v_out_normal, 0.5) : mix(UP, -step_axis * rd_sign, 0.25));
        }

        float step_size = min(steps.x, min(steps.y, steps.z));
        step_axis = vec3(lessThanEqual(steps, vec3(step_size)));
        vec3 old_p = p;
        p += rd * step_size;
        if (abs(p.z) < depth && alpha > 0.1) {
            float dz = (depth - old_p.z) / rd.z;
            t += dz;
            old_p += rd * dz;
            return Hit(old_p / 16, delta, t / 16, UP);
        }
        t += step_size;

        vec3 new_cell = cell + step_axis * rd_sign;
        cell += step_axis * rd_sign;
        if (!inBound(cell)) discard;
        steps += rd_step * step_axis - step_size;
    }
    discard;
}

void main() {
    mat3 TBN = tbnNormalTangent(v_aspect * v_normal, v_tangent.xyz);
    vec2 ray_origin = fract(v_uv_color * atlasSize / 16) - 0.5;
    Hit h = DDA(vec3(ray_origin, v_z), normalize(v_eye_pos * TBN) * vec3(1, -v_tangent.w, 1));

    vec4 base = correctedSample(gtexture, h.delta);
    if (base.a < 0.1) discard;

    float prio = dot(vec3(0.5, 2.5, 1.5), v_normal) + 6 * dot(vec3(1, 2, -4), mod(floor(v_mid + cameraPosition), 2));
    vec3 hitPos = v_eye_pos + normalize(v_eye_pos) * (h.dist + 0.00005 * prio);
    vec4 projected = projectionMatrix * modelViewMatrix * vec4(hitPos, 1);
    gl_FragDepth = 0.5 + 0.5 * projected.z / projected.w;

    float light;
    if (v_light_type == FLAG_FLAT_LIGHTING) {
        light = 1;
    } else if (v_light_type == FLAG_DARK_LIGHTING) {
        light = 0.75;
    } else {
        vec3 normal = normalize(TBN * (h.side * vec3(1, -v_tangent.w, 1)));
        float occlusion = mix(0.5, 0.9, 1 + 8 * h.pos.z);
        light = occlusion * dot(normal * normal, vec3(0.6, 0.25 * normal.y + 0.75, 0.8));
    }
    vec3 tint = texture(lightmap, v_uv_light).rgb * v_color;
    outColor = base * vec4(tint * light, 1);
    //outColor = vec4(float(has(v_mc_id,1))/2+float(has(v_mc_id,2)), float(has(v_mc_id,4))/2+float(has(v_mc_id,8)), v_light_type/3, 1);
}