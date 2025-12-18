#type compute
#version 430 core
#includeGlobalSource

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;


layout(std430, binding = 0) buffer buffer0 
{
	Chunk chunksData[]; 
};

layout(std430, binding = 1) buffer buffer1 
{
	ChunkQuads chunksQuads[]; 
};
layout(std430, binding = 5) buffer buffer5
{
	uint renderData[];
};

layout(std430, binding = 9) buffer buffer9
{
	bool shouldRedrawChunk[]; 
};

ivec3 offsets[6] = ivec3[6](
    ivec3(0, 1, 0),
    ivec3(0, -1, 0),
    ivec3(1, 0, 0),
    ivec3(-1, 0, 0),
    ivec3(0, 0, 1),
    ivec3(0, 0, -1)
);

// AO corner offsets for each face direction
// For each face, 4 vertices, each vertex needs 2 side neighbors + 1 corner neighbor
// Format: [face][vertex][0=side1, 1=side2, 2=corner]
const ivec3 aoOffsets[6][4][3] = ivec3[6][4][3](
    // +Y (top face) - vertices go around the top
    ivec3[4][3](
        ivec3[3](ivec3(1,0,0), ivec3(0,0,-1), ivec3(1,0,-1)),   // v0
        ivec3[3](ivec3(-1,0,0), ivec3(0,0,-1), ivec3(-1,0,-1)), // v1
        ivec3[3](ivec3(-1,0,0), ivec3(0,0,1), ivec3(-1,0,1)),   // v2
        ivec3[3](ivec3(1,0,0), ivec3(0,0,1), ivec3(1,0,1))      // v3
    ),
    // -Y (bottom face)
    ivec3[4][3](
        ivec3[3](ivec3(1,0,0), ivec3(0,0,1), ivec3(1,0,1)),
        ivec3[3](ivec3(-1,0,0), ivec3(0,0,1), ivec3(-1,0,1)),
        ivec3[3](ivec3(-1,0,0), ivec3(0,0,-1), ivec3(-1,0,-1)),
        ivec3[3](ivec3(1,0,0), ivec3(0,0,-1), ivec3(1,0,-1))
    ),
    // +X (east face)
    ivec3[4][3](
        ivec3[3](ivec3(0,-1,0), ivec3(0,0,1), ivec3(0,-1,1)),
        ivec3[3](ivec3(0,-1,0), ivec3(0,0,-1), ivec3(0,-1,-1)),
        ivec3[3](ivec3(0,1,0), ivec3(0,0,-1), ivec3(0,1,-1)),
        ivec3[3](ivec3(0,1,0), ivec3(0,0,1), ivec3(0,1,1))
    ),
    // -X (west face)
    ivec3[4][3](
        ivec3[3](ivec3(0,-1,0), ivec3(0,0,-1), ivec3(0,-1,-1)),
        ivec3[3](ivec3(0,-1,0), ivec3(0,0,1), ivec3(0,-1,1)),
        ivec3[3](ivec3(0,1,0), ivec3(0,0,1), ivec3(0,1,1)),
        ivec3[3](ivec3(0,1,0), ivec3(0,0,-1), ivec3(0,1,-1))
    ),
    // +Z (south face)
    ivec3[4][3](
        ivec3[3](ivec3(-1,0,0), ivec3(0,-1,0), ivec3(-1,-1,0)),
        ivec3[3](ivec3(1,0,0), ivec3(0,-1,0), ivec3(1,-1,0)),
        ivec3[3](ivec3(1,0,0), ivec3(0,1,0), ivec3(1,1,0)),
        ivec3[3](ivec3(-1,0,0), ivec3(0,1,0), ivec3(-1,1,0))
    ),
    // -Z (north face)
    ivec3[4][3](
        ivec3[3](ivec3(1,0,0), ivec3(0,-1,0), ivec3(1,-1,0)),
        ivec3[3](ivec3(-1,0,0), ivec3(0,-1,0), ivec3(-1,-1,0)),
        ivec3[3](ivec3(-1,0,0), ivec3(0,1,0), ivec3(-1,1,0)),
        ivec3[3](ivec3(1,0,0), ivec3(0,1,0), ivec3(1,1,0))
    )
);

// Check if a block at the given position is solid (for AO calculation)
bool isBlockSolid(ivec3 localPos, ivec3 chunkOffset) {
    // Handle chunk boundary crossing
    ivec3 actualPos = localPos;
    ivec3 actualChunkOffset = chunkOffset;

    if (actualPos.x < 0) { actualPos.x += CHUNK_SIDE_LENGTH; actualChunkOffset.x -= 1; }
    else if (actualPos.x >= CHUNK_SIDE_LENGTH) { actualPos.x -= CHUNK_SIDE_LENGTH; actualChunkOffset.x += 1; }
    if (actualPos.y < 0) { actualPos.y += CHUNK_SIDE_LENGTH; actualChunkOffset.y -= 1; }
    else if (actualPos.y >= CHUNK_SIDE_LENGTH) { actualPos.y -= CHUNK_SIDE_LENGTH; actualChunkOffset.y += 1; }
    if (actualPos.z < 0) { actualPos.z += CHUNK_SIDE_LENGTH; actualChunkOffset.z -= 1; }
    else if (actualPos.z >= CHUNK_SIDE_LENGTH) { actualPos.z -= CHUNK_SIDE_LENGTH; actualChunkOffset.z += 1; }

    uvec3 neighborChunk = uvec3(
        gl_WorkGroupID.x + actualChunkOffset.x,
        gl_WorkGroupID.y + actualChunkOffset.y,
        gl_WorkGroupID.z + actualChunkOffset.z
    );

    // Out of world bounds = not solid (air)
    if (neighborChunk.x >= WORLD_WIDTH || neighborChunk.y >= WORLD_HEIGHT || neighborChunk.z >= WORLD_WIDTH) {
        return false;
    }

    uint neighborChunkIndex = getChunkIndex(neighborChunk.x, neighborChunk.y, neighborChunk.z);
    uint blockType = chunksData[neighborChunkIndex].blockTypes[actualPos.x][actualPos.y][actualPos.z];

    return blockType != air;
}

// Calculate AO value for a vertex (0-3, where 0 = fully occluded, 3 = no occlusion)
uint calculateVertexAO(ivec3 blockPos, int faceDir, int vertexIndex) {
    ivec3 side1Offset = aoOffsets[faceDir][vertexIndex][0];
    ivec3 side2Offset = aoOffsets[faceDir][vertexIndex][1];
    ivec3 cornerOffset = aoOffsets[faceDir][vertexIndex][2];

    // Offset by face normal to check neighbors of the exposed face
    ivec3 faceOffset = offsets[faceDir];
    ivec3 checkPos = blockPos + faceOffset;

    bool side1 = isBlockSolid(checkPos + side1Offset, ivec3(0));
    bool side2 = isBlockSolid(checkPos + side2Offset, ivec3(0));
    bool corner = isBlockSolid(checkPos + cornerOffset, ivec3(0));

    // Standard voxel AO formula
    if (side1 && side2) {
        return 0u;  // Fully occluded
    }
    return 3u - uint(side1) - uint(side2) - uint(corner);
}

int blockTypeAndNormalToTextureId(uint blockType, int normal){
	switch(blockType){
	case air:
		return dirt;
	case dirt_block:
		return dirt;
	case grass_block:
		switch(normal){
		case 0://positive y
			return grass_block_top;
		case 1://negative y
			return dirt;
		case 2://positive x
			return grass_block_side;
		case 3://negative x
			return grass_block_side;
		case 4://positive z
			return grass_block_side;
		case 5://negative z
			return grass_block_side;
		}
	case tnt_block:
		switch(normal){
		case 0://positive y
			return tnt_top;
		case 1://negative y
			return tnt_bottom;
		case 2://positive x
			return tnt_side;
		case 3://negative x
			return tnt_side;
		case 4://positive z
			return tnt_side;
		case 5://negative z
			return tnt_side;
		}
	case bedrock_block:
		return bedrock;
	case stone_block:
		return stone;
	}
}

void main() {
	uint chunkIndex = getChunkIndex(gl_WorkGroupID.x,gl_WorkGroupID.y,gl_WorkGroupID.z);
	if(!shouldRedrawChunk[chunkIndex]){
		return;	
	}
	int index = 0;
	for(int x=0;x<CHUNK_SIDE_LENGTH;x++){
		for(int y=0;y<CHUNK_SIDE_LENGTH;y++){
			for(int z=0;z<CHUNK_SIDE_LENGTH;z++){
				uint blockType = chunksData[chunkIndex].blockTypes[x][y][z];
				if(blockType != 0){
					ivec3 blockLocalPosition = ivec3(x,y,z);
					uint blockLocalPositionBinary = blockLocalPosition.x | blockLocalPosition.y<<4 | blockLocalPosition.z <<8;
					for(int n = 0;n<6;n++){
						ivec3 neighbourPos = blockLocalPosition + offsets[n];
						ivec3 neighbourChunkOffset = ivec3(0);

						// Handle boundaries
						if (neighbourPos.x < 0) { neighbourPos.x = CHUNK_SIDE_LENGTH - 1; neighbourChunkOffset.x = -1; }
						else if (neighbourPos.x >= CHUNK_SIDE_LENGTH) { neighbourPos.x = 0; neighbourChunkOffset.x = 1; }
						if (neighbourPos.y < 0) { neighbourPos.y = CHUNK_SIDE_LENGTH - 1; neighbourChunkOffset.y = -1; }
						else if (neighbourPos.y >= CHUNK_SIDE_LENGTH) { neighbourPos.y = 0; neighbourChunkOffset.y = 1; }
						if (neighbourPos.z < 0) { neighbourPos.z = CHUNK_SIDE_LENGTH - 1; neighbourChunkOffset.z = -1; }
						else if (neighbourPos.z >= CHUNK_SIDE_LENGTH) { neighbourPos.z = 0; neighbourChunkOffset.z = 1; }

						uint neighbourType = 1;
						uvec3 neighbourChunkPosition = uvec3( gl_WorkGroupID.x + neighbourChunkOffset.x,
															gl_WorkGroupID.y + neighbourChunkOffset.y,
															gl_WorkGroupID.z + neighbourChunkOffset.z
															);	
						if(!(neighbourChunkPosition.x>=WORLD_WIDTH ||neighbourChunkPosition.y>=WORLD_HEIGHT ||neighbourChunkPosition.z>=WORLD_WIDTH ||
						neighbourChunkPosition.x<0 ||neighbourChunkPosition.y<0 ||neighbourChunkPosition.z<0)){
							uint neighbourChunkIndex = getChunkIndex(neighbourChunkPosition.x,neighbourChunkPosition.y,neighbourChunkPosition.z);
							neighbourType = chunksData[neighbourChunkIndex]
								.blockTypes[neighbourPos.x][neighbourPos.y][neighbourPos.z];
						}
						if (neighbourType == 0) {
							// Calculate AO for all 4 vertices of this face
							uint ao0 = calculateVertexAO(blockLocalPosition, n, 0);
							uint ao1 = calculateVertexAO(blockLocalPosition, n, 1);
							uint ao2 = calculateVertexAO(blockLocalPosition, n, 2);
							uint ao3 = calculateVertexAO(blockLocalPosition, n, 3);

							// Pack AO into bits 19-26 (2 bits per vertex)
							uint packedAO = (ao0 << 19) | (ao1 << 21) | (ao2 << 23) | (ao3 << 25);

							chunksQuads[chunkIndex].blockQuads[index] =
								blockLocalPositionBinary |
								(n << 12) |
								(blockTypeAndNormalToTextureId(blockType, n) << 15) |
								packedAO;
							index++;
						}
					}

				}

			}
		}
	}
	renderData[chunkIndex] = index;

}
