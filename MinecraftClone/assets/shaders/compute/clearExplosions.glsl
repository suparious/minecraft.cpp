#type compute
#version 430 core
#includeGlobalSource

// 256 threads per chunk (16x16 grid), each thread clears one Y-column
layout (local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

layout(std430, binding = 0) buffer buffer0
{
	Chunk chunksData[];
};

void main() {
	uint chunkIndex = gl_WorkGroupID.x + gl_WorkGroupID.y * WORLD_WIDTH + gl_WorkGroupID.z * WORLD_WIDTH * WORLD_HEIGHT;

	// Early exit if no explosions in this chunk
	if (!chunksData[chunkIndex].hasExplosion) {
		return;
	}

	// Each thread handles one X-Z column (all Y values)
	uint x = gl_LocalInvocationID.x;
	uint z = gl_LocalInvocationID.y;

	for (int y = 0; y < CHUNK_SIDE_LENGTH; y++) {
		chunksData[chunkIndex].explosions[x][y][z] = 0;
	}

	// Only first thread resets the flag (avoid race condition)
	if (gl_LocalInvocationIndex == 0) {
		chunksData[chunkIndex].hasExplosion = false;
	}
}
