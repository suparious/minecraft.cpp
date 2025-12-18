# VoxelEngine - Claude Agent Context

**Project**: GPU-Accelerated Minecraft Clone
**Language**: C++23
**Graphics API**: OpenGL 4.3+ (Compute Shaders)
**Build Systems**: Premake5 (Windows), CMake (Linux/WSL)

---

## Quick Start

### Windows (Visual Studio 2022)
```bash
# Clone with submodules
git clone --recursive https://github.com/suparious/minecraft.cpp.git
cd VoxelEngine

# Generate VS solution
./GenerateProjects.bat

# Open VoxelEngine.sln in Visual Studio, build (F7), run
```

### Linux / WSL (CMake)
```bash
# Clone with submodules
git clone --recursive https://github.com/suparious/minecraft.cpp.git
cd VoxelEngine

# Install dependencies (Ubuntu/Debian)
sudo apt install build-essential cmake libglfw3-dev libgl1-mesa-dev libx11-dev libxrandr-dev libxi-dev libxxf86vm-dev

# Build
mkdir build && cd build
cmake ..
make -j$(nproc)

# Run (from project root, needs assets/)
./bin/MinecraftClone
```

---

## Project Structure

```
VoxelEngine/
├── VoxelEngine/                 # Engine core (static library)
│   ├── src/
│   │   ├── pch.h/cpp           # Precompiled headers
│   │   ├── VoxelEngine.h       # Public API
│   │   ├── Platform/           # Window/Input (GLFW-based, cross-platform)
│   │   └── VoxelEngine/
│   │       ├── Core/           # Application, layers, events
│   │       ├── Events/         # Event system
│   │       ├── Renderer/       # OpenGL rendering, shaders, textures
│   │       ├── ImGui/          # Debug UI
│   │       └── Debug/          # Profiling
│   └── vendor/                 # Dependencies (git submodules)
│       ├── GLFW/               # Window/input
│       ├── GLAD/               # OpenGL loader
│       ├── glm/                # Math library
│       ├── imgui/              # UI
│       ├── spdlog/             # Logging
│       ├── stb_image/          # Image loading
│       ├── tracy/              # Profiler
│       └── raudio/             # Audio
│
├── MinecraftClone/             # Application layer
│   ├── src/
│   │   ├── MinecraftCloneApp.cpp  # Entry point
│   │   ├── Layers/
│   │   │   ├── GameLayer.h/cpp    # Main game logic
│   │   │   └── GameConfig.h       # World configuration
│   │   └── Overlays/
│   │       └── DebugOverlay.h/cpp
│   └── assets/
│       ├── shaders/            # GLSL shaders
│       │   ├── compute/        # GPU compute shaders (8 files)
│       │   ├── drawTerrain.glsl
│       │   └── tntInstancing.glsl
│       ├── textures/           # Block textures (16x16 PNG)
│       └── audio/              # Sound effects (OGG)
│
├── doc/                        # Documentation
│   └── ROADMAP.md             # Development roadmap
├── premake5.lua               # Windows build config
├── CMakeLists.txt             # Linux/WSL build config
└── CLAUDE.md                  # This file
```

---

## Architecture Overview

### Engine Design
- **Layer System**: Game logic in layers (GameLayer), UI in overlays (DebugOverlay)
- **Event System**: Keyboard, mouse, window events dispatched through layers
- **Renderer**: OpenGL 4.3+ with compute shaders for GPU parallelism

### GPU Pipeline (Compute Shaders)
```
World Generation:
  generateBlocks.glsl → Block types per chunk (terrain)
  generateQuads.glsl  → Mesh generation (greedy meshing)

TNT Physics:
  initTntData.glsl        → Initialize TNT state
  activateTnt.glsl        → Raycast activation
  explodeTnts.glsl        → Physics update (velocity, gravity)
  propagateExplosions.glsl → BFS explosion propagation
  updateTntTransforms.glsl → Position updates
  clearExplosions.glsl    → Reset tracking
```

### Key Classes
- `Application` - Main loop, layer management
- `Window` - GLFW window wrapper
- `Shader` / `ShaderLibrary` - GLSL compilation and management
- `Buffer` / `StorageBuffer` - GPU data (VBO, SSBO)
- `GameLayer` - Main game logic, chunk management, rendering

---

## Configuration

Edit `MinecraftClone/src/Layers/GameConfig.h`:

```cpp
// World size (chunks)
constexpr int WORLD_WIDTH = 35;   // X/Z dimension
constexpr int WORLD_HEIGHT = 20;  // Y dimension

// Block/chunk constants
constexpr int CHUNK_SIDE_LENGTH = 16;
constexpr int SURFACE_LEVEL = 100;

// TNT demo
constexpr int HOW_MANY_TNT_TO_SPAWN = 10'000'000;
```

**Performance Tips**:
- Lower `WORLD_WIDTH` to 25 if GPU memory limited
- Lower `HOW_MANY_TNT_TO_SPAWN` to 100,000 for testing

---

## Current Capabilities

### Implemented
- Block rendering with texture atlas
- Flat terrain generation (grass/dirt/stone/bedrock)
- TNT explosion physics (10M entities)
- First-person camera movement (WASD + mouse)
- Basic audio (explosions, fuse)
- Debug overlay (ImGui)

### NOT Implemented (See ROADMAP.md)
- Block placement/breaking (manual)
- Inventory/crafting
- Mobs/entities (except TNT)
- Caves, biomes, trees
- Lighting/shadows
- Day/night cycle
- World saving/loading
- Menus

---

## Development Guidelines

### Adding New Block Types
1. Add enum value in `globalInclude.glsl` (shared shader constants)
2. Add texture to `assets/textures/texture_pack/`
3. Update texture atlas generation in `GameLayer.cpp`
4. Add texture ID mapping in `globalInclude.glsl`

### Adding New Compute Shaders
1. Create `.glsl` file in `assets/shaders/compute/`
2. Load shader in `GameLayer::OnAttach()` using `ShaderLibrary`
3. Dispatch with `glDispatchCompute()` and proper barriers

### Modifying World Generation
- Edit `assets/shaders/compute/generateBlocks.glsl`
- Uses 3D dispatch: one thread per block
- Output to chunk SSBO (Storage Buffer)

### Platform-Specific Code
The `Platform/Windows/` code is actually **cross-platform GLFW** despite the name.
For true platform-specific code, use:
```cpp
#ifdef VE_PLATFORM_WINDOWS
    // Windows-specific
#elif defined(VE_PLATFORM_LINUX)
    // Linux-specific
#endif
```

---

## Build Configurations

| Config | Use Case | Defines |
|--------|----------|---------|
| Debug | Development, OpenGL error logging | `VE_DEBUG` |
| Release | Testing with optimizations | `VE_RELEASE` |
| Dist | Distribution, no debug overhead | `VE_DIST` |

---

## Dependencies (Git Submodules)

| Library | Purpose | Notes |
|---------|---------|-------|
| GLFW | Windowing/input | Cross-platform |
| GLAD | OpenGL loader | Generated for 4.3 core |
| GLM | Math (vec3, mat4) | Header-only |
| ImGui | Debug UI | Docking branch |
| spdlog | Logging | Header-only |
| stb_image | PNG loading | Single header |
| Tracy | Profiling | Optional |
| raudio | Audio playback | From raylib |

If submodules are missing:
```bash
git submodule update --init --recursive
```

---

## Debugging Tips

### OpenGL Errors
Run in Debug configuration - errors logged to console via `spdlog`.

### Performance Profiling
Tracy profiler integrated. Look for `VE_PROFILE_FUNCTION` and `VE_PROFILE_SCOPE` macros.

### Common Issues
- **Black screen**: Check shader compilation errors in console
- **Crash on startup**: Lower `WORLD_WIDTH` or `HOW_MANY_TNT_TO_SPAWN`
- **Missing textures**: Verify `assets/` folder is in working directory

---

## Roadmap

See `doc/ROADMAP.md` for the complete development plan covering:
- Phase 1: Foundation (block interaction, inventory, physics)
- Phase 2: World (terrain, caves, biomes)
- Phase 3: Gameplay (crafting, tools, survival)
- Phase 4: Entities (mobs, items)
- Phase 5: Environment (lighting, day/night, weather)
- Phase 6: Polish (menus, saving, audio)

---

## Contributing

1. Fork the repository
2. Create feature branch
3. Follow existing code style (`.clang-format` provided)
4. Test on both Windows and Linux if possible
5. Submit PR with description

---

**Last Updated**: December 17, 2025
