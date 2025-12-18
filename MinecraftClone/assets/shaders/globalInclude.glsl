#define GRAVITY -28.57
#define TNT_EXPLOSION_STRENGTH 4

#define air 0
#define dirt_block 1
#define grass_block 2
#define tnt_block 3
#define bedrock_block 4
#define stone_block 5

#define top 0
#define bottom 1
#define east 2
#define west 3
#define south 4
#define north 5


#define dirt 0
#define grass_block_top 1
#define grass_block_side 2
#define stone 3
#define tnt_bottom 4
#define tnt_side 5
#define tnt_top 6
#define bedrock 7

uint getChunkIndex(uint chunkX, uint chunkY, uint chunkZ){
	return chunkX+chunkY*WORLD_WIDTH+chunkZ*WORLD_WIDTH*WORLD_HEIGHT;
}

// ============================================================================
// Fast hash-based noise functions (optimized for GPU)
// ============================================================================

// Fast hash function - returns 0.0 to 1.0
float hash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// 2D gradient noise (faster than classic Perlin)
float noise2D(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    // Quintic interpolation for smoother results
    vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

    // Four corners
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    // Bilinear interpolation
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Fractal Brownian Motion - layered noise for natural terrain
float fbm(vec2 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    float maxValue = 0.0;

    for (int i = 0; i < octaves; i++) {
        value += amplitude * noise2D(p * frequency);
        maxValue += amplitude;
        amplitude *= 0.5;
        frequency *= 2.0;
    }

    return value / maxValue;  // Normalize to 0-1
}

// 3D hash for cave generation (if needed later)
float hash3D(vec3 p) {
    p = fract(p * vec3(0.1031, 0.1030, 0.0973));
    p += dot(p, p.yxz + 33.33);
    return fract((p.x + p.y) * p.z);
}

struct Chunk {
	uint x;
	uint y;
	uint z;
	bool hasExplosion;
	uint blockTypes[CHUNK_SIDE_LENGTH][CHUNK_SIDE_LENGTH][CHUNK_SIDE_LENGTH];
	uint explosions[CHUNK_SIDE_LENGTH][CHUNK_SIDE_LENGTH][CHUNK_SIDE_LENGTH];
};

struct ChunkQuads {
	uint blockQuads[FACES_PER_CHUNK];
};

struct TntEntity{
	vec3 position;
	vec3 velocity;
	float secondsUntilExplode;
	bool visible; 
	bool justBlewUp; 
};