#version 460

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D normals;
uniform ivec2 atlasSize;
uniform mat4 projectionMatrix;
uniform mat4 modelViewMatrix;
uniform vec3 cameraPosition;

// DRAWBUFFERS:0
layout(location=0) out vec4 outColor;

in vec3 v_color;
in vec3 v_normal;
in vec4 v_tangent;
in vec2 v_uv_color;
in vec2 v_uv_light;
in vec3 v_eye_pos;
in vec3 v_mid;

in float v_aspect;
in float v_z;
in vec2 v_min;
in vec2 v_max;

mat3 tbnNormalTangent(vec3 normal, vec3 tangent) {
    vec3 bitangent = cross(normal, tangent);
    return mat3(tangent, bitangent, normal);
}

struct Hit {
    vec3 pos;
    vec2 delta;
    float dist;
    float side;
};

vec4 correctedSample(sampler2D sampler, vec2 uv) {
    return textureGrad(sampler, v_uv_color+uv/atlasSize, dFdx(v_uv_color), dFdy(v_uv_color));
}

bool inBound(vec3 p) {
    return p.x < (v_max.x-0.5)*16 && p.x >= (v_min.x-0.51)*16 && p.y < (v_max.y-0.5)*16 && p.y >= (v_min.y-0.51)*16;
}

Hit DDA(vec3 ro, vec3 rd) {
    ro *= 16;
    vec3 p = ro;
    vec3 cell = floor(p);
    vec3 origin = cell;

    vec3 next_edge = vec3(greaterThan(rd, vec3(0)));
    vec3 steps = (next_edge - fract(p)) / rd;
    vec3 rd_step = abs(1 / rd);
    vec3 rd_sign = sign(rd);

    float t = 0;
    for (int i = 0; i < 32 ; i++) {
        vec2 delta = (cell - origin).xy;
        vec4 albedo = correctedSample(gtexture, delta);
        float alpha = albedo.a;
        float depth = dot(albedo.rgb, vec3(0.3, 0.3, 0.4));
        //float depth = 4*correctedSample(normals, delta).a-3;
        if (abs(p.z) < depth && alpha > 0.1) {
            return Hit(p/16, delta, t/16, i == 0 ? 1 : 0.8);
        }

        float step_size = min(steps.x, min(steps.y, steps.z));
        vec3 old_p = p;
        p += rd * step_size;
        if (abs(p.z) < depth && alpha > 0.1) {
            float dz = (depth - old_p.z)/rd.z;
            t += dz;
            old_p += rd * dz;
            return Hit(old_p/16, delta, t/16, 1);
        }
        t += step_size;

        vec3 step_axis = vec3(lessThanEqual(steps, vec3(step_size)));
        vec3 new_cell = cell + step_axis * rd_sign;
        cell += step_axis * rd_sign;
        if (!inBound(cell) || p.z < -2) {
            discard;
        }

        steps += rd_step * step_axis - step_size;
    }
    discard;
}

void main() {
    mat3 TBN = tbnNormalTangent(v_aspect * v_normal, v_tangent.xyz);
    vec2 ray_origin = fract(v_uv_color * atlasSize/16) - 0.5;
    Hit h = DDA(vec3(ray_origin, v_z), normalize(v_eye_pos*TBN)*vec3(1,-v_tangent.w,1));
    float occlusion = mix(0.5, 0.9, 1 + h.pos.z * 8);
    float prio = dot(vec3(0.5, 2.5, 1.5), v_normal) + 6 * dot(vec3(1, 2, -4), mod(floor(v_mid + cameraPosition), 2));
    vec3 hitPos = v_eye_pos + normalize(v_eye_pos) * (h.dist + prio * 0.00005);
    vec4 projected = projectionMatrix * modelViewMatrix * vec4(hitPos, 1);
    gl_FragDepth = 0.5+0.5*+projected.z/projected.w;

    vec4 base = correctedSample(gtexture, h.delta);
    if (base.a < 0.1) discard;
    vec3 tint = texture(lightmap, v_uv_light).rgb * v_color;
    outColor = base * vec4(tint * h.side * occlusion, 1);
}
