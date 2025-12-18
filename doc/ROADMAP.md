# VoxelEngine - Development Roadmap

**Document Version**: 1.0
**Created**: December 17, 2025
**Status**: Planning Phase

---

## Current State Summary

VoxelEngine is a **GPU-accelerated voxel engine** written in C++ with OpenGL compute shaders. It's currently a technical showcase for TNT explosion physics rather than a complete Minecraft clone.

| Aspect | Status | Notes |
|--------|--------|-------|
| **Rendering** | Strong | Multi-draw indirect, texture atlas, compute shaders |
| **World Gen** | Basic | Flat terrain only, no biomes/caves |
| **Gameplay** | Missing | No inventory, crafting, survival mechanics |
| **Entities** | Partial | Only TNT, no mobs |
| **Audio** | Partial | Explosions only |
| **UI** | Missing | Debug overlay only |

### Technical Highlights
- ~17,500 lines of C++ code
- 10 compute shaders for parallel GPU execution
- Multi-draw indirect rendering (single draw call for all chunks)
- Greedy meshing for optimized geometry
- Handles 10M TNT entities at interactive framerates

---

## Phase 1: Foundation (Core Systems)

These are **blocking dependencies** for everything else.

### 1.1 Block Interaction System ✅ IMPLEMENTED
**Priority**: P0 (Critical)
**Effort**: Medium
**Dependencies**: None (raycast exists for TNT)

- [x] Raycast from camera to determine targeted block
- [x] Block breaking (left click) - removes block
- [x] Block placement (right click) on adjacent face
- [x] Block highlight (30% brightness boost)
- [x] Chunk mesh regeneration on block change
- [x] Hotbar UI with 9 slots (keys 1-9)
- [ ] Block breaking animation/particles (future)
- [ ] Block breaking/placing sounds (future)

### 1.2 Inventory System
**Priority**: P1
**Effort**: Medium-High
**Dependencies**: Block interaction (drops items)

- [ ] Item data structure (ID, count, metadata)
- [ ] 36-slot inventory (27 storage + 9 hotbar)
- [ ] Hotbar selection (1-9 keys, scroll wheel)
- [ ] Inventory UI (E key to open)
- [ ] Item pickup from broken blocks
- [ ] Stack management (max 64)

### 1.3 Expanded Block Types
**Priority**: P1
**Effort**: Medium
**Dependencies**: Block interaction, inventory

- [ ] Add 20+ essential blocks:
  - Stone variants, ores (coal, iron, gold, diamond)
  - Wood (logs, planks), leaves, sand, gravel
  - Glass, wool, cobblestone, bricks
- [ ] Block properties: hardness, tool requirements, drops
- [ ] Expand texture atlas (pack already has many textures)

### 1.4 Player Physics & Collision
**Priority**: P0 (Critical)
**Effort**: Medium
**Dependencies**: None

- [ ] AABB collision detection with blocks
- [ ] Gravity (not currently applied to player)
- [ ] Jumping (space when grounded)
- [ ] Ground detection (isOnGround state)
- [ ] Prevent walking through blocks
- [ ] Sprinting (double-tap W or Ctrl)

---

## Phase 2: World (Procedural Generation & Simulation)

Transform the flat world into interesting, living terrain.

### 2.0 Game Tick System (Server Tick)
**Priority**: P1
**Effort**: Medium
**Dependencies**: None
**Notes**: Foundation for all world simulation

- [ ] Implement game tick loop (20 ticks/second like Minecraft)
- [ ] Random tick for block updates (subset of world each tick)
- [ ] Scheduled tick queue for delayed events
- [ ] Tick event dispatch to world systems
- [ ] Time-of-day counter (24000 ticks = 20 minute day)

### 2.0.1 Block Update System
**Priority**: P1
**Effort**: Medium
**Dependencies**: Game tick

- [ ] Grass spreading (dirt adjacent to grass + light → grass)
- [ ] Leaf decay (leaves without nearby log blocks decay)
- [ ] Farmland hydration (water nearby)
- [ ] Fire spread and burn-out
- [ ] Ice melting (near heat sources)
- [ ] Snow layer accumulation

### 2.1 Heightmap Terrain ✅ IMPLEMENTED
**Priority**: P1
**Effort**: Medium
**Dependencies**: None (modifies existing shader)

- [x] Replace flat surface with Perlin/Simplex noise
- [x] Multiple octaves for natural-looking terrain (FBM)
- [x] Hills, valleys, mountains (amplitude scaling)
- [x] Smooth transitions between heights
- [x] Update `generateBlocks.glsl` compute shader

### 2.2 Cave Generation
**Priority**: P2
**Effort**: Medium-High
**Dependencies**: Heightmap terrain

- [ ] 3D Perlin worms or cellular automata
- [ ] Carve caves through stone layer
- [ ] Cave openings to surface
- [ ] Underground ravines
- [ ] Proper air pocket handling

### 2.3 Ore Distribution
**Priority**: P2
**Effort**: Low-Medium
**Dependencies**: Expanded block types, caves

- [ ] Coal: y=5-128, common
- [ ] Iron: y=5-64, moderate
- [ ] Gold: y=5-32, rare
- [ ] Diamond: y=5-16, very rare
- [ ] Ore vein clustering (3D noise pockets)

### 2.4 Biome System
**Priority**: P4
**Effort**: High
**Dependencies**: Heightmap terrain

- [ ] Temperature + humidity noise maps
- [ ] Biome types: Plains, Forest, Desert, Tundra, Ocean
- [ ] Biome-specific surface blocks (sand, snow, grass)
- [ ] Biome-specific terrain shape
- [ ] Smooth biome transitions

### 2.5 Tree & Vegetation
**Priority**: P3
**Effort**: Medium
**Dependencies**: Biomes, expanded blocks

- [ ] Oak trees (trunk + leaves structure)
- [ ] Tree placement noise (not every block)
- [ ] Flowers, tall grass, mushrooms
- [ ] Biome-specific vegetation

### 2.6 Dynamic Chunk Loading
**Priority**: P3
**Effort**: High (architectural change)
**Dependencies**: All world gen systems

- [ ] Chunk loading radius around player
- [ ] Unload distant chunks (free GPU memory)
- [ ] Threaded chunk generation (CPU side)
- [ ] Chunk priority queue (closest first)
- [ ] Seamless loading (no stutter)

---

## Phase 3: Gameplay (Survival Mechanics)

Make it a game, not just a world viewer.

### 3.1 Crafting System
**Priority**: P2
**Effort**: High
**Dependencies**: Inventory, expanded blocks

- [ ] 2x2 crafting grid (inventory)
- [ ] 3x3 crafting table
- [ ] Recipe registry (JSON or code)
- [ ] Essential recipes: tools, torches, chests, doors
- [ ] Shapeless vs shaped recipes

### 3.2 Tool System
**Priority**: P2
**Effort**: Medium
**Dependencies**: Crafting, inventory

- [ ] Tool types: Pickaxe, Shovel, Axe, Sword, Hoe
- [ ] Material tiers: Wood, Stone, Iron, Gold, Diamond
- [ ] Mining speed based on tool + block type
- [ ] Tool durability
- [ ] Tool requirement for certain blocks (iron for diamond)

### 3.3 Health & Damage
**Priority**: P2
**Effort**: Medium
**Dependencies**: Player physics (fall detection)

- [ ] 10 hearts (20 HP)
- [ ] Fall damage (>3 blocks)
- [ ] Explosion damage (TNT already exists!)
- [ ] Respawn on death
- [ ] Hearts UI overlay

### 3.4 Hunger System
**Priority**: P3
**Effort**: Medium
**Dependencies**: Health, inventory

- [ ] 10 hunger bars
- [ ] Hunger drain on movement/actions
- [ ] Food items (apple, bread, meat)
- [ ] Eating animation
- [ ] Health regeneration when full
- [ ] Starvation damage when empty

---

## Phase 4: Entities (Mobs & Items)

Bring the world to life.

### 4.1 Entity Component System
**Priority**: P3
**Effort**: High (architectural)
**Dependencies**: Player physics (reuse collision)

- [ ] Entity base class (position, velocity, AABB)
- [ ] Component architecture (Health, AI, Render, Physics)
- [ ] Entity manager (spawn, despawn, update)
- [ ] Entity-block collision
- [ ] Entity-entity collision

### 4.2 Item Entities
**Priority**: P2
**Effort**: Medium
**Dependencies**: ECS, inventory

- [ ] Dropped items (from block breaking)
- [ ] Item bobbing animation
- [ ] Magnetic pickup range
- [ ] Despawn timer (5 minutes)
- [ ] Item merging (same type nearby)

### 4.3 Passive Mobs
**Priority**: P4
**Effort**: Medium-High
**Dependencies**: ECS

- [ ] Pig, Cow, Sheep, Chicken
- [ ] Wander AI (random movement)
- [ ] Basic model (could start with cubes)
- [ ] Spawning in grass biomes
- [ ] Drops on death (meat, leather, wool)

### 4.4 Hostile Mobs
**Priority**: P4
**Effort**: High
**Dependencies**: ECS, health system, day/night

- [ ] Zombie, Skeleton, Creeper, Spider
- [ ] Chase AI (pathfinding to player)
- [ ] Attack mechanics (melee, ranged)
- [ ] Night spawning / cave spawning
- [ ] Loot drops

---

## Phase 5: Environment (Atmosphere)

Make the world feel alive.

### 5.1 Lighting System
**Priority**: P2
**Effort**: High (major shader changes)
**Dependencies**: None (enhances existing rendering)

- [ ] Sky light (propagates down from sky)
- [ ] Block light (torches, lava, glowstone)
- [ ] Light level per block (0-15)
- [x] Smooth lighting / ambient occlusion ✅ IMPLEMENTED (per-vertex AO at mesh generation)
- [ ] Light propagation on block change
- [x] Distance fog ✅ IMPLEMENTED (150-400 block fade)

### 5.2 Day/Night Cycle
**Priority**: P3
**Effort**: Medium
**Dependencies**: Lighting system

- [ ] 20-minute full cycle
- [ ] Sun/moon rendering
- [ ] Sky color transitions
- [ ] Light level changes
- [ ] Mob spawning tied to darkness

### 5.3 Water & Fluids
**Priority**: P3
**Effort**: High
**Dependencies**: Expanded blocks, player physics

- [ ] Water block (transparent, animated)
- [ ] Water physics (spreading, source blocks)
- [ ] Lava (same mechanics, different speed)
- [ ] Swimming mechanics
- [ ] Underwater fog

### 5.4 Weather
**Priority**: P4
**Effort**: Medium
**Dependencies**: Biomes, lighting

- [ ] Rain particles
- [ ] Snow particles (in cold biomes)
- [ ] Thunder/lightning
- [ ] Weather state machine

---

## Phase 6: Polish (UI & Persistence)

Make it feel like a complete game.

### 6.1 Main Menu
**Priority**: P4
**Effort**: Medium
**Dependencies**: None (ImGui already available)

- [ ] Title screen with background
- [ ] Singleplayer / Multiplayer / Settings / Quit
- [ ] World selection screen
- [ ] Create new world (seed, game mode)

### 6.2 Pause Menu & Settings
**Priority**: P3
**Effort**: Medium
**Dependencies**: None

- [ ] ESC to pause
- [ ] Resume / Settings / Save & Quit
- [ ] Graphics settings (render distance, vsync)
- [ ] Controls settings (sensitivity, keybinds)
- [ ] Audio settings (volume sliders)

### 6.3 HUD Elements
**Priority**: P2
**Effort**: Medium
**Dependencies**: Health, hunger, inventory

- [ ] Hearts display
- [ ] Hunger bars
- [ ] Hotbar with item icons
- [ ] Crosshair
- [ ] Experience bar (optional)

### 6.4 World Saving/Loading
**Priority**: P4
**Effort**: High
**Dependencies**: Dynamic chunk loading, inventory

- [ ] Chunk serialization (binary or NBT-like)
- [ ] Player data (position, inventory, health)
- [ ] World metadata (seed, time, spawn point)
- [ ] Region files (group chunks for efficiency)
- [ ] Auto-save interval

### 6.5 Audio Expansion
**Priority**: P4
**Effort**: Medium (mostly asset work)
**Dependencies**: raudio already integrated

- [ ] Block breaking/placing sounds
- [ ] Footstep sounds (surface-dependent)
- [ ] Ambient sounds (wind, birds, caves)
- [ ] Background music (calm tracks)
- [ ] UI sounds (click, inventory)

---

## Priority Matrix

| Priority | Features | Rationale |
|----------|----------|-----------|
| **P0** | Block Interaction, Player Physics | Everything depends on these |
| **P1** | Inventory, Heightmap Terrain, Health | Core gameplay loop |
| **P2** | Crafting, Caves, Lighting, Tools, HUD | Survival mechanics |
| **P3** | Mobs, Day/Night, Water, Menus | World feels alive |
| **P4** | Biomes, Weather, Saving, Audio | Polish and persistence |

---

## Recommended Starting Point

Start with **Phase 1.1 (Block Interaction)** because:

1. **Raycast already exists** - Used for TNT activation, can be adapted
2. **Mesh regeneration exists** - `generateQuads` compute shader handles it
3. **Immediate gameplay value** - Most impactful single feature
4. **Tests the architecture** - Validates the chunk update pipeline

---

## Technical Notes

### Architecture Strengths
- Clean separation: VoxelEngine (library) vs MinecraftClone (app)
- GPU-first design with compute shaders
- Layer-based extensibility
- Event-driven input system
- Modern C++23 features

### Performance Considerations
- All terrain in GPU SSBOs (Storage Buffer Objects)
- Compute shader parallelization
- Greedy meshing reduces vertex count ~80%
- Multi-draw indirect = 1 draw call for all chunks

### Build Support
- **Windows**: Premake5 + Visual Studio 2022 (original)
- **Linux/WSL**: CMake (added for CI/CD automation)

---

## Changelog

- **v1.1** (2025-12-17):
  - Added Game Tick System (2.0) and Block Update System (2.0.1)
  - Marked Block Interaction System (1.1) as IMPLEMENTED
  - Marked Heightmap Terrain (2.1) as IMPLEMENTED
  - Marked Ambient Occlusion and Distance Fog as IMPLEMENTED
- **v1.0** (2025-12-17): Initial roadmap created from codebase analysis
