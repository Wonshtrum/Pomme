// Pomme Shaders
// Copyright (C) 2025  Wonshtrum
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

#version 150

uniform vec3 chunkOffset;

in vec3 vaPosition;
in vec4 vaColor;
in vec3 vaNormal;
in vec2 vaUV0;
in uvec2 vaUV2;
in vec3 at_midBlock;
in vec4 at_tangent;
in vec3 mc_Entity;

out VS_OUT {
    vec3 color;
    vec3 normal;
    vec4 tangent;
    vec2 uv_color;
    vec2 uv_light;
    vec3 bpos;
    int mc_id;
} v_vertex;

void main() {
    v_vertex.color = vaColor.rgb;
    v_vertex.normal = vaNormal;
    v_vertex.tangent = at_tangent;
    v_vertex.uv_color = vaUV0;
    v_vertex.uv_light = vaUV2 / 256.0 + 1. / 32.;
    v_vertex.bpos = at_midBlock / 64.;
    v_vertex.mc_id = mc_Entity.x < 0 ? 0 : int(mc_Entity.x);
    gl_Position = vec4(vaPosition + chunkOffset, 1);
}
