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

// Terrain generation parameters
const float TERRAIN_SCALE = 0.02;        // Horizontal scale (smaller = larger features)
const float TERRAIN_HEIGHT = 25.0;       // Max height variation
const float BASE_HEIGHT = float(SURFACE_LEVEL);  // Base terrain height
const int TERRAIN_OCTAVES = 4;           // Noise detail layers

// Calculate terrain height at world position using FBM noise
int getTerrainHeight(int worldX, int worldZ) {
    vec2 pos = vec2(float(worldX), float(worldZ)) * TERRAIN_SCALE;

    // Multi-octave noise for natural-looking terrain
    float noiseValue = fbm(pos, TERRAIN_OCTAVES);

    // Add some larger-scale variation for hills
    float largeScale = noise2D(pos * 0.3) * 0.5 + 0.5;
    noiseValue = mix(noiseValue, largeScale, 0.3);

    // Convert to height (centered around BASE_HEIGHT)
    return int(BASE_HEIGHT + (noiseValue - 0.5) * TERRAIN_HEIGHT * 2.0);
}

void main() {
	uint chunkIndex = getChunkIndex(gl_WorkGroupID.x,gl_WorkGroupID.y,gl_WorkGroupID.z);
	shouldRedrawWorld = true;
	shouldRedrawChunk[chunkIndex] = true;

	uint chunkX = gl_WorkGroupID.x * CHUNK_SIDE_LENGTH;
	uint chunkY = gl_WorkGroupID.y * CHUNK_SIDE_LENGTH;
	uint chunkZ = gl_WorkGroupID.z * CHUNK_SIDE_LENGTH;

	chunksData[chunkIndex].x = chunkX;
	chunksData[chunkIndex].y = chunkY;
	chunksData[chunkIndex].z = chunkZ;

	for(int x=0;x<CHUNK_SIDE_LENGTH;x++){
		for(int z=0;z<CHUNK_SIDE_LENGTH;z++){
			uint blockX = x + chunkX;
			uint blockZ = z + chunkZ;

			// Calculate terrain height at this X,Z position
			int surfaceLevel = getTerrainHeight(int(blockX), int(blockZ));

			for(int y=0;y<CHUNK_SIDE_LENGTH;y++){
				uint blockY = y + chunkY;

				// Default block type based on height
				uint blockType = air;

				if(blockY == 0){
					// Bedrock at bottom
					blockType = bedrock_block;
				} else if(blockY < surfaceLevel){
					// Underground layers
					if(blockY < surfaceLevel - 4){
						blockType = stone_block;
					} else {
						blockType = dirt_block;
					}
				} else if (blockY == surfaceLevel){
					// Surface
					blockType = grass_block;
				}

				// TNT cube override (demo feature)
				if(blockY >= TNT_MIN_Y && blockY < TNT_MAX_Y &&
				   blockX >= TNT_MIN_X && blockX < TNT_MAX_X &&
				   blockZ >= TNT_MIN_Z && blockZ < TNT_MAX_Z){
					blockType = tnt_block;
				}

				chunksData[chunkIndex].blockTypes[x][y][z] = blockType;
				chunksData[chunkIndex].explosions[x][y][z] = 0;
				chunksData[chunkIndex].hasExplosion = false;
			}
		}
	}
}
