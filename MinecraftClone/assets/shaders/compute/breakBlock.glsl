#type compute
#version 430 core
#includeGlobalSource

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(std430, binding = 0) buffer buffer0
{
	Chunk chunksData[];
};

layout(std430, binding = 6) buffer buffer6
{
	TntEntity tnts[];
};

layout(std430, binding = 8) buffer buffer8
{
	bool shouldRedrawWorld;
};

layout(std430, binding = 9) buffer buffer9
{
	bool shouldRedrawChunk[];
};

layout(std430, binding = 10) buffer buffer10
{
	bool shouldPlayFuseSound;
};

// Output: whether a block was broken (for audio feedback)
layout(std430, binding = 13) buffer buffer13
{
	int blockWasBroken;
};

uniform vec3 u_CameraPos;
uniform vec3 u_RayDirection;

void main() {
	float step = 0.1;
	float maxDistance = 8.0;  // Typical Minecraft reach distance
	vec3 startPosition = u_CameraPos;
	vec3 position = u_CameraPos;

	blockWasBroken = 0;

	while(length(startPosition - position) < maxDistance) {
		position = position + u_RayDirection * step;

		uvec3 chunkPosition = uvec3(floor(position / 16.0));

		// Bounds check - skip if outside world
		if (chunkPosition.x >= WORLD_WIDTH ||
		    chunkPosition.y >= WORLD_HEIGHT ||
		    chunkPosition.z >= WORLD_WIDTH) {
			continue;
		}

		ivec3 localPos = ivec3(floor(position)) - ivec3(chunkPosition * 16u);

		// Clamp local position to valid range
		if (localPos.x < 0 || localPos.x >= CHUNK_SIDE_LENGTH ||
		    localPos.y < 0 || localPos.y >= CHUNK_SIDE_LENGTH ||
		    localPos.z < 0 || localPos.z >= CHUNK_SIDE_LENGTH) {
			continue;
		}

		uint chunkIndex = getChunkIndex(chunkPosition.x, chunkPosition.y, chunkPosition.z);
		uint blockType = chunksData[chunkIndex].blockTypes[localPos.x][localPos.y][localPos.z];

		if (blockType != air && blockType != bedrock_block) {
			// Handle TNT activation
			if (blockType == tnt_block) {
				vec3 actualChunkPosition = vec3(chunkPosition) * 16.0;
				vec3 blockOrigin = actualChunkPosition + vec3(localPos);
				int relX = int(blockOrigin.x - TNT_MIN_X);
				int relY = int(blockOrigin.y - TNT_MIN_Y);
				int relZ = int(blockOrigin.z - TNT_MIN_Z);

				// Check if this TNT is within the TNT cube bounds
				if (relX >= 0 && relX < TNT_SIDE_LENGTH &&
				    relY >= 0 && relY < TNT_SIDE_LENGTH &&
				    relZ >= 0 && relZ < TNT_SIDE_LENGTH) {
					int tntIndex = relY * TNT_SIDE_LENGTH * TNT_SIDE_LENGTH + relZ * TNT_SIDE_LENGTH + relX;
					tnts[tntIndex].position = blockOrigin;
					tnts[tntIndex].velocity = vec3(0, 6, 0);
					tnts[tntIndex].visible = true;
					tnts[tntIndex].secondsUntilExplode = 4.0;
					shouldPlayFuseSound = true;
				}
			}

			// Break the block (set to air)
			chunksData[chunkIndex].blockTypes[localPos.x][localPos.y][localPos.z] = air;

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

			blockWasBroken = 1;
			break;
		}
	}
}
