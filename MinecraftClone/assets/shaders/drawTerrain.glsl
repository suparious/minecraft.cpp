#type vertex
#version 460 core
#includeGlobalSource
layout(std430, binding = 0) readonly buffer buffer0
{
	Chunk chunksData[];
};
layout(std430, binding = 1) readonly buffer buffer1
{
	ChunkQuads chunksQuads[];
};

layout(std430, binding = 2) readonly buffer terrainAtlasCoordsBuffer
{
	vec2 terrainAtlasCoords[];
};
layout(std430, binding = 3) readonly buffer texturePositionOffsetsBuffer
{
	vec2 texturePositionOffsets[];
};

const vec3 offset = vec3(0.5, 0.5, 0.5);
const vec3 facePositions[6][4] = vec3[6][4](
    // +Y (top)
    vec3[4](
        vec3( 0.5,  0.5, -0.5) + offset,
        vec3(-0.5,  0.5, -0.5) + offset,
        vec3(-0.5,  0.5,  0.5) + offset,
        vec3( 0.5,  0.5,  0.5) + offset
    ),
    // -Y (bottom)
    vec3[4](
        vec3( 0.5, -0.5,  0.5) + offset,
        vec3(-0.5, -0.5,  0.5) + offset,
        vec3(-0.5, -0.5, -0.5) + offset,
        vec3( 0.5, -0.5, -0.5) + offset
    ),
    // +X (east)
    vec3[4](
        vec3( 0.5, -0.5,  0.5) + offset,
        vec3( 0.5, -0.5, -0.5) + offset,
        vec3( 0.5,  0.5, -0.5) + offset,
        vec3( 0.5,  0.5,  0.5) + offset
    ),
    // -X (west)
    vec3[4](
        vec3(-0.5, -0.5, -0.5) + offset,
        vec3(-0.5, -0.5,  0.5) + offset,
        vec3(-0.5,  0.5,  0.5) + offset,
        vec3(-0.5,  0.5, -0.5) + offset
    ),
    // +Z (south)
    vec3[4](
        vec3(-0.5, -0.5,  0.5) + offset,
        vec3( 0.5, -0.5,  0.5) + offset,
        vec3( 0.5,  0.5,  0.5) + offset,
        vec3(-0.5,  0.5,  0.5) + offset
    ),
    // -Z (north)
    vec3[4](
        vec3( 0.5, -0.5, -0.5) + offset,
        vec3(-0.5, -0.5, -0.5) + offset,
        vec3(-0.5,  0.5, -0.5) + offset,
        vec3( 0.5,  0.5, -0.5) + offset
    )
);

int indices[6] = {0, 1, 2, 2, 3, 0};

// AO curve - converts 0-3 AO value to light multiplier
const float aoValues[4] = float[4](0.4, 0.6, 0.8, 1.0);

uniform mat4 u_ViewProjection;
uniform mat4 u_Transform;
uniform vec3 u_CameraPos;

// Block selection highlighting
uniform int u_SelectedBlockX;
uniform int u_SelectedBlockY;
uniform int u_SelectedBlockZ;
uniform int u_HasSelection;

out vec2 v_TexCoord;
out vec4 v_StaticLight;
out float v_FogFactor;
flat out int v_IsHighlighted;

void main()
{
	const int index = gl_VertexID/6;

    const uint chunkId = gl_BaseInstance;
    uint chunkX = chunksData[chunkId].x;
    uint chunkY = chunksData[chunkId].y;
    uint chunkZ = chunksData[chunkId].z;

	const uint packedData = chunksQuads[chunkId].blockQuads[index];
	const int currVertexID = gl_VertexID % 6;

	const uint x = bitfieldExtract(packedData,0,4);
	const uint y = bitfieldExtract(packedData,4,4);
	const uint z = bitfieldExtract(packedData,8,4);

	const uint normalId = bitfieldExtract(packedData,12,3);
	const uint texId = bitfieldExtract(packedData,15,4);

	// Extract AO values for all 4 vertices (packed in bits 19-26)
	const uint ao0 = bitfieldExtract(packedData, 19, 2);
	const uint ao1 = bitfieldExtract(packedData, 21, 2);
	const uint ao2 = bitfieldExtract(packedData, 23, 2);
	const uint ao3 = bitfieldExtract(packedData, 25, 2);

	// Get AO for current vertex (indices maps 6 vertices to 4 corners: 0,1,2,2,3,0)
	const int cornerIndex = indices[currVertexID];
	uint vertexAO;
	if (cornerIndex == 0) vertexAO = ao0;
	else if (cornerIndex == 1) vertexAO = ao1;
	else if (cornerIndex == 2) vertexAO = ao2;
	else vertexAO = ao3;

	float aoMultiplier = aoValues[vertexAO];

	vec3 position = vec3(x+chunkX, y+chunkY, z+chunkZ);

	// Check if this block is the selected/highlighted one
	ivec3 blockPos = ivec3(x+chunkX, y+chunkY, z+chunkZ);
	ivec3 selectedPos = ivec3(u_SelectedBlockX, u_SelectedBlockY, u_SelectedBlockZ);
	v_IsHighlighted = (u_HasSelection == 1 && blockPos == selectedPos) ? 1 : 0;

	position += facePositions[normalId][indices[currVertexID]];

    v_TexCoord = terrainAtlasCoords[texId]+texturePositionOffsets[indices[currVertexID]];

	// Directional light based on face normal
	float directionalLight = 1.0;
    if(normalId == east || normalId == west){
		directionalLight = 0.8;
    }else if(normalId == south || normalId == north){
		directionalLight = 0.7;
    }else if(normalId == bottom){
		directionalLight = 0.5;
	}

	// Combine directional light with AO
	float finalLight = directionalLight * aoMultiplier;
    v_StaticLight = vec4(finalLight, finalLight, finalLight, 1.0);

	// Calculate fog factor based on distance from camera
	float distance = length(position - u_CameraPos);
	const float fogStart = 150.0;   // Fog starts at this distance
	const float fogEnd = 400.0;     // Full fog at this distance
	v_FogFactor = clamp((distance - fogStart) / (fogEnd - fogStart), 0.0, 1.0);

	gl_Position = u_ViewProjection*u_Transform*vec4(position, 1.0);
}

#type fragment
#version 430 core

out vec4 color;
in vec2 v_TexCoord;
in vec4 v_StaticLight;
in float v_FogFactor;
flat in int v_IsHighlighted;

layout (binding = 0) uniform sampler2D u_Texture;

// Sky/fog color - light blue gradient feel
const vec3 fogColor = vec3(0.6, 0.75, 0.9);

void main()
{
	vec4 texColor = texture(u_Texture, v_TexCoord) * v_StaticLight;

	// Apply fog - blend towards fog color based on distance
	vec3 finalColor = mix(texColor.rgb, fogColor, v_FogFactor);

	// Apply highlight brightness boost (30% brighter)
	if (v_IsHighlighted == 1) {
		finalColor = finalColor * 1.3;
	}

	color = vec4(finalColor, texColor.a);
}
