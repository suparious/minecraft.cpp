#type compute
#version 430 core
#includeGlobalSource

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(std430, binding = 0) readonly buffer buffer0
{
	Chunk chunksData[];
};

// Block selection output (binding 12)
// Must match C++ struct and placeBlock.glsl layout
layout(std430, binding = 12) buffer buffer12
{
	ivec3 selectedBlockPos;
	int _pad0;
	ivec3 selectedFaceNormal;
	int hasSelection;
};

uniform vec3 u_CameraPos;
uniform vec3 u_RayDirection;

// Face normals matching the face order in globalInclude.glsl
const ivec3 faceNormals[6] = ivec3[6](
	ivec3( 0,  1,  0),  // top (+Y)
	ivec3( 0, -1,  0),  // bottom (-Y)
	ivec3( 1,  0,  0),  // east (+X)
	ivec3(-1,  0,  0),  // west (-X)
	ivec3( 0,  0,  1),  // south (+Z)
	ivec3( 0,  0, -1)   // north (-Z)
);

// Determine which face of a block was hit based on ray direction
// We use the ray direction to determine which face we're approaching
int getFaceFromRayDirection(vec3 rayDir) {
	vec3 absDir = abs(rayDir);

	// Find the dominant axis of the ray direction
	if (absDir.y >= absDir.x && absDir.y >= absDir.z) {
		// Looking mostly up/down - hit top or bottom face
		return rayDir.y < 0.0 ? top : bottom;
	} else if (absDir.x >= absDir.y && absDir.x >= absDir.z) {
		// Looking mostly left/right - hit east or west face
		return rayDir.x < 0.0 ? east : west;
	} else {
		// Looking mostly forward/back - hit south or north face
		return rayDir.z < 0.0 ? south : north;
	}
}

void main() {
	float step = 0.1;
	float maxDistance = 8.0;  // Typical Minecraft reach distance
	vec3 position = u_CameraPos;
	ivec3 lastBlockPos = ivec3(floor(position));

	hasSelection = 0;

	for (float dist = 0.0; dist < maxDistance; dist += step) {
		position = u_CameraPos + u_RayDirection * dist;

		// Get the block position we're currently in
		ivec3 currentBlockPos = ivec3(floor(position));

		// Skip if we're in the same block as last check
		if (currentBlockPos == lastBlockPos && dist > 0.0) {
			continue;
		}

		// Calculate chunk and local position
		uvec3 chunkPosition = uvec3(currentBlockPos) / uint(CHUNK_SIDE_LENGTH);

		// Bounds check - skip if outside world
		if (chunkPosition.x >= WORLD_WIDTH ||
		    chunkPosition.y >= WORLD_HEIGHT ||
		    chunkPosition.z >= WORLD_WIDTH ||
		    currentBlockPos.x < 0 || currentBlockPos.y < 0 || currentBlockPos.z < 0) {
			lastBlockPos = currentBlockPos;
			continue;
		}

		ivec3 localPos = currentBlockPos - ivec3(chunkPosition * uint(CHUNK_SIDE_LENGTH));

		// Clamp local position to valid range
		if (localPos.x < 0 || localPos.x >= CHUNK_SIDE_LENGTH ||
		    localPos.y < 0 || localPos.y >= CHUNK_SIDE_LENGTH ||
		    localPos.z < 0 || localPos.z >= CHUNK_SIDE_LENGTH) {
			lastBlockPos = currentBlockPos;
			continue;
		}

		uint chunkIndex = getChunkIndex(chunkPosition.x, chunkPosition.y, chunkPosition.z);
		uint blockType = chunksData[chunkIndex].blockTypes[localPos.x][localPos.y][localPos.z];

		if (blockType != air) {
			// Found a solid block
			selectedBlockPos = currentBlockPos;

			// Determine which face we entered from by checking which axis we crossed
			ivec3 blockDiff = currentBlockPos - lastBlockPos;
			if (blockDiff.x != 0) {
				selectedFaceNormal = ivec3(blockDiff.x > 0 ? -1 : 1, 0, 0);
			} else if (blockDiff.y != 0) {
				selectedFaceNormal = ivec3(0, blockDiff.y > 0 ? -1 : 1, 0);
			} else if (blockDiff.z != 0) {
				selectedFaceNormal = ivec3(0, 0, blockDiff.z > 0 ? -1 : 1);
			} else {
				// Started inside a block or first check - use ray direction
				int faceHit = getFaceFromRayDirection(u_RayDirection);
				selectedFaceNormal = faceNormals[faceHit];
			}

			hasSelection = 1;
			break;
		}

		lastBlockPos = currentBlockPos;
	}
}
