#version 450

in vec3 pos;
in vec3 nor;
in vec2 tex;
out vec3 wpositionGeom;
out vec3 wnormalGeom;
out vec2 texCoordGeom;
out vec4 lampPosGeom;
uniform mat4 W;
uniform mat3 N;
uniform mat4 LWVP;

void main() {
	texCoordGeom = tex;
	wpositionGeom = vec3(W * vec4(pos, 1.0)) / voxelgiDimensions;
	wnormalGeom = normalize(N * nor);
	gl_Position = vec4(0.0, 0.0, 0.0, 1.0);
	lampPosGeom = LWVP * vec4(pos, 1.0);
}
