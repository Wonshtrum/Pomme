#version 150

#include "lib.glsl"

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D normals;
uniform mat4 projectionMatrix;
uniform mat4 modelViewMatrix;
uniform vec3 cameraPosition;
uniform int renderStage;

// DRAWBUFFERS:0
layout(location = 0) out vec4 outColor;

in vec3 v_normal;
in vec4 v_tangent;
flat in vec3 v_out_normal;

in vec3 v_color;
in vec2 v_uv_color;
in vec2 v_uv_light;
in vec3 v_eye_pos;
in vec3 v_mid;
in float v_z;

flat in ivec2 v_texture_size;
flat in ivec2 v_min;
flat in ivec2 v_max;
flat in ivec2 v_span;
in float v_factor;
in float v_aspect;

flat in int v_light_type;
flat in int v_mc_id;


mat3 tbnNormalTangent(vec3 normal, vec3 tangent) {
    vec3 bitangent = cross(normal, tangent);
    return mat3(tangent, bitangent, normal);
}

vec2 UV;
vec4 correctedSample(sampler2D sampler, vec2 delta) {
    return textureGrad(sampler, (UV + v_min + delta) / v_texture_size, dFdx(v_uv_color), dFdy(v_uv_color));
}

bool inBound(vec3 p) {
    return abs(p.z) <= ceil(float(EXTRUSION)) && p.x >= 0 && p.y >= 0 && p.x < v_span.x && p.y < v_span.y;
}

struct Hit {
    vec3 pos;
    vec2 delta;
    float dist;
    vec3 side;
    int n;
};
Hit DDA(vec3 p, vec3 rd) {
    vec3 cell = floor(p);
    vec3 origin = cell;

    vec3 next_edge = vec3(greaterThan(rd, vec3(0)));
    vec3 steps = (next_edge - fract(p)) / rd;
    vec3 rd_step = abs(1 / rd);
    vec3 rd_sign = sign(rd);

    vec3 step_axis;
    float t = 0;
    int i;
    for (i = 0; i < 32; i++) {
        vec2 delta = (cell - origin).xy;
        vec4 albedo = correctedSample(gtexture, delta);
        float alpha = albedo.a;
        float depth = EXTRUSION*max(0.01, dot(albedo.rgb, vec3(0.3, 0.3, 0.4)));
        //if (depth < 0.01) depth = 1;
        //float depth = 4*correctedSample(normals, delta).a-3;
        if (abs(p.z) < depth && alpha > 0.1) {
            return Hit(p, delta, t, i == 0 ? mix(UP, v_out_normal, 0.5) : mix(UP, -step_axis * rd_sign, 0.5), i);
        }

        float step_size = min(steps.x, min(steps.y, steps.z));
        step_axis = vec3(lessThanEqual(steps, vec3(step_size)));
        vec3 old_p = p;
        p += rd * step_size;
        if (abs(p.z) < depth && alpha > 0.1) {
            //float dz = (depth - old_p.z) / rd.z;
            float dz = abs((depth - abs(old_p.z)) / rd.z);
            t += dz;
            old_p += rd * dz;
            return Hit(old_p, delta, t, UP, i);
        }
        t += step_size;

        vec3 new_cell = cell + step_axis * rd_sign;
        cell += step_axis * rd_sign;
        if (!inBound(cell)) break;
        steps += rd_step * step_axis - step_size;
    }
    //return Hit(p, vec2(0), t, vec3(0), i);
    discard;
}

void main() {
    if (renderStage == MC_RENDER_STAGE_PARTICLES) {
        vec4 base = texture2D(gtexture, v_uv_color);
        if (base.a < 0.1) discard;
        outColor = base * vec4(v_color, 1);
        gl_FragDepth = 0.5 + 0.5 * v_z;
        return;
    }

    UV = clamp(v_uv_color * v_texture_size - v_min, vec2(0.001), v_span-0.001);
    outColor = vec4(1.*v_max/v_texture_size, 0, 1);
    outColor = vec4(fract(UV+v_min), 0, 1);
    outColor = vec4(v_color, 1);
    //outColor = vec4(v_min/32., 0, 1);

    mat3 TBN = tbnNormalTangent(v_aspect * v_normal, v_tangent.xyz);
    Hit h = DDA(vec3(UV, v_z), normalize(v_eye_pos) * TBN * vec3(1, -v_tangent.w, 1));
    //outColor = vec4(h.n/16.);

    vec4 base = correctedSample(gtexture, h.delta);
    if (base.a < 0.1) discard;

    float light;
    vec3 normal;
    if (v_light_type == FLAG_FLAT_LIGHTING) {
        light = 1;
    } else if (v_light_type == FLAG_DARK_LIGHTING) {
        light = 0.75;
    } else {
        normal = normalize(TBN * (h.side * vec3(1, -v_tangent.w, 1)));
        float occlusion = mix(0.9, 1.1, h.pos.z / EXTRUSION);
        light = occlusion * dot(normal * normal, vec3(0.6, 0.25 * normal.y + 0.75, 0.8));
    }

#ifdef ENTITY_STAGE
    float prio = -10*dot(normal * normal, vec3(0.6, 0.25 * normal.y + 0.75, 0.8));
#else
    float prio = dot(vec3(0.5, 2.5, 1.5), v_normal) + 6 * dot(vec3(1, 2, -4), mod(floor(v_mid + cameraPosition), 2)) - 0*sign(h.pos.z);
#endif
    vec3 hitPos = v_eye_pos + normalize(v_eye_pos) * (h.dist * v_factor + 0.00005 * prio);
    vec4 projected = projectionMatrix * modelViewMatrix * vec4(hitPos, 1);
    gl_FragDepth = 0.5 + 0.5 * projected.z / projected.w;

    vec3 tint = texture(lightmap, v_uv_light).rgb * v_color;
    outColor = base * vec4(tint * light, 1);
}