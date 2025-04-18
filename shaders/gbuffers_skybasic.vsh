#version 150

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform vec3 chunkOffset;

in vec3 vaPosition;
in vec4 vaColor;

out vec4 v_color;

void main() {
    v_color = vaColor;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(vaPosition + chunkOffset, 1);
}
