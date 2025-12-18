#type compute
#version 430 core
#includeGlobalSource

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(std430, binding = 0) buffer buffer0
{
	Chunk chunksData[];
};

layout(std430, binding = 8) buffer buffer8
{
	bool shouldRedrawWorld;
};

layout(std430, binding = 9) buffer buffer9
{
	bool shouldRedrawChunk[];
};

// Block selection input (from selectBlock shader)
layout(std430, binding = 12) readonly buffer buffer12
{
	ivec3 selectedBlockPos;
	int _pad0;
	ivec3 selectedFaceNormal;
	int hasSelection;
};

// Output: whether a block was placed (for audio feedback)
layout(std430, binding = 14) buffer buffer14
{
	int blockWasPlaced;
};

uniform int u_BlockType;
uniform vec3 u_CameraPos;

void main() {
	blockWasPlaced = 0;

	// Can't place if nothing is selected
	if (hasSelection == 0) {
		return;
	}

	// Calculate placement position (adjacent to selected block)
	ivec3 placePos = selectedBlockPos + selectedFaceNormal;

	// Validate placement position is within world bounds
	if (placePos.x < 0 || placePos.y < 0 || placePos.z < 0) {
		return;
	}

	int worldMaxX = int(WORLD_WIDTH * CHUNK_SIDE_LENGTH);
	int worldMaxY = int(WORLD_HEIGHT * CHUNK_SIDE_LENGTH);
	int worldMaxZ = int(WORLD_WIDTH * CHUNK_SIDE_LENGTH);

	if (placePos.x >= worldMaxX || placePos.y >= worldMaxY || placePos.z >= worldMaxZ) {
		return;
	}

	// Don't place block if it would be inside the player
	// Simple check: only deny if camera is inside the block itself
	vec3 placePosF = vec3(placePos) + vec3(0.5);
	vec3 diff = abs(u_CameraPos - placePosF);
	// Player is inside block if within 0.4 units on all axes (accounts for player width)
	if (diff.x < 0.4 && diff.y < 0.9 && diff.z < 0.4) {
		return;
	}

	// Calculate chunk and local position
	uvec3 chunkPosition = uvec3(placePos) / uint(CHUNK_SIDE_LENGTH);
	ivec3 localPos = placePos - ivec3(chunkPosition * uint(CHUNK_SIDE_LENGTH));

	uint chunkIndex = getChunkIndex(chunkPosition.x, chunkPosition.y, chunkPosition.z);

	// Only place if target is air
	if (chunksData[chunkIndex].blockTypes[localPos.x][localPos.y][localPos.z] != air) {
		return;
	}

	// Place the block
	chunksData[chunkIndex].blockTypes[localPos.x][localPos.y][localPos.z] = u_BlockType;

	// Signal redraw
	shouldRedrawWorld = true;
	shouldRedrawChunk[chunkIndex] = true;

	// Flag adjacent chunks if block is on boundary
	if (localPos.x == 0 && chunkPosition.x > 0)
		shouldRedrawChunk[getChunkIndex(chunkPosition.x - 1, chunkPosition.y, chunkPosition.z)] = true;
	else if (localPos.x == CHUNK_SIDE_LENGTH - 1 && chunkPosition.x < WORLD_WIDTH - 1)
		shouldRedrawChunk[getChunkIndex(chunkPosition.x + 1, chunkPosition.y, chunkPosition.z)] = true;

	if (localPos.y == 0 && chunkPosition.y > 0)
		shouldRedrawChunk[getChunkIndex(chunkPosition.x, chunkPosition.y - 1, chunkPosition.z)] = true;
	else if (localPos.y == CHUNK_SIDE_LENGTH - 1 && chunkPosition.y < WORLD_HEIGHT - 1)
		shouldRedrawChunk[getChunkIndex(chunkPosition.x, chunkPosition.y + 1, chunkPosition.z)] = true;

	if (localPos.z == 0 && chunkPosition.z > 0)
		shouldRedrawChunk[getChunkIndex(chunkPosition.x, chunkPosition.y, chunkPosition.z - 1)] = true;
	else if (localPos.z == CHUNK_SIDE_LENGTH - 1 && chunkPosition.z < WORLD_WIDTH - 1)
		shouldRedrawChunk[getChunkIndex(chunkPosition.x, chunkPosition.y, chunkPosition.z + 1)] = true;

	blockWasPlaced = 1;
}
