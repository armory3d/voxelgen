#version 450

layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;

in vec3 wpositionGeom[];
in vec3 wnormalGeom[];
in vec2 texCoordGeom[];
in vec4 lampPosGeom[];
out vec3 wposition;
out vec3 wnormal;
out vec4 lampPos;
out vec2 texCoord;

void main() {
	const vec3 p1 = wpositionGeom[1] - wpositionGeom[0];
	const vec3 p2 = wpositionGeom[2] - wpositionGeom[0];
	const vec3 p = abs(cross(p1, p2));
	for (uint i = 0; i < 3; ++i) {
	    wposition = wpositionGeom[i];
	    wnormal = wnormalGeom[i];
	    lampPos = lampPosGeom[i];
	    texCoord = texCoordGeom[i];
	    if (p.z > p.x && p.z > p.y) {
	        gl_Position = vec4(wposition.x, wposition.y, 0.0, 1.0);
	    }
	    else if (p.x > p.y && p.x > p.z) {
	        gl_Position = vec4(wposition.y, wposition.z, 0.0, 1.0);
	    }
	    else {
	        gl_Position = vec4(wposition.x, wposition.z, 0.0, 1.0);
	    }
	    EmitVertex();
	}
	EndPrimitive();
}
