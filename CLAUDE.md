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
cd minecraft.cpp

# Generate VS solution
./GenerateProjects.bat

# Open VoxelEngine.sln in Visual Studio, build (F7), run
```

### Linux / WSL (CMake)
```bash
# Clone with submodules
git clone --recursive https://github.com/suparious/minecraft.cpp.git
cd minecraft.cpp

# Install dependencies (Ubuntu/Debian)
sudo apt install build-essential cmake libglfw3-dev libgl1-mesa-dev libx11-dev libxrandr-dev libxi-dev libxxf86vm-dev

# Build
mkdir build && cd build
cmake ..
make -j$(nproc)

# Run (from project root, needs assets/)
./bin/MinecraftClone
```

### Cross-Compile for Windows (from WSL/Linux using MinGW)
```bash
# Install MinGW cross-compiler
sudo apt install mingw-w64

# Configure and build
mkdir build-windows && cd build-windows
cmake .. \
  -DCMAKE_SYSTEM_NAME=Windows \
  -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc \
  -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ \
  -DCMAKE_RC_COMPILER=x86_64-w64-mingw32-windres \
  -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)

# Output: bin/MinecraftClone.exe (run from Windows)
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
├── release.sh                 # Build script for releases
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
- Perlin noise terrain generation (hills/valleys with grass/dirt/stone/bedrock)
- Block placement and breaking (raycast selection, hotbar)
- TNT explosion physics (10M entities)
- First-person camera movement (WASD + mouse)
- Ambient occlusion (per-vertex AO)
- Distance fog (150-400 block fade)
- Basic audio (explosions, fuse)
- Debug overlay (ImGui, Windows only)

### NOT Implemented (See ROADMAP.md)
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
- Uses 256 threads per chunk (16x16 local workgroup), one thread per X-Z column
- Each thread generates all Y blocks in its column
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

See `doc/ROADMAP.md` for the complete development plan.

**Already Implemented:**
- Block interaction (breaking/placing, raycast, hotbar)
- Heightmap terrain (Perlin noise hills/valleys)
- Ambient occlusion (per-vertex AO)
- Distance fog (150-400 block fade)

**Phases:**
- Phase 1: Foundation (inventory, player physics) - *partially done*
- Phase 2: World (caves, ores, biomes, trees)
- Phase 3: Gameplay (crafting, tools, survival)
- Phase 4: Entities (mobs, items)
- Phase 5: Environment (lighting, day/night, water)
- Phase 6: Polish (menus, saving, audio)

---

## Contributing

1. Fork the repository
2. Create feature branch
3. Follow existing code style (`.clang-format` provided)
4. Test on both Windows and Linux if possible
5. Submit PR with description

---

## Claude Agent Notes (For Future Sessions)

**CRITICAL WARNINGS - READ BEFORE MAKING CHANGES:**

1. **GLSL Version Compatibility (RESOLVED):** We now use GLSL 4.50 + `GL_ARB_shader_draw_parameters` extension with a `#define gl_BaseInstance gl_BaseInstanceARB` for broad driver compatibility. This was the correct fix for Mesa/WSL2 support.

2. **Do NOT modify code to work around build errors.** If cross-compilation fails (e.g., Tracy with MinGW), tell the user to build natively instead of hacking the codebase.

3. **Always verify claims before stating them.** When asked "what's the impact of X?", actually grep/search the code for affected features. Don't guess.

4. **WSL GPU Support:** Mesa's llvmpipe is software rendering. For real GPU:
   ```bash
   export GALLIUM_DRIVER=d3d12  # Required for AMD/Intel GPUs in WSL
   ```

5. **Shader Compatibility Fix:** `drawTerrain.glsl` uses GLSL 4.50 with ARB extension for broad Mesa compatibility:
   ```glsl
   #version 450 core
   #extension GL_ARB_shader_draw_parameters : require
   #define gl_BaseInstance gl_BaseInstanceARB
   ```
   Note: GLSL 4.60 provides `gl_BaseInstance` directly. GLSL 4.50 + extension provides `gl_BaseInstanceARB`.

6. **Tracy Profiler:** Disabled by default. pch.h has a guard to default TRACY_ENABLE=0. When building with `-DTRACY_ENABLE=ON`, the guard is bypassed. Tracy ETW code does NOT compile with MinGW.

7. **Build Systems:**
   - **Windows native**: Use Premake5 + Visual Studio (GenerateProjects.bat) - user must run from Windows terminal.
   - **Linux/WSL native**: Use CMake (`mkdir build && cd build && cmake .. && make -j$(nproc)`).
   - **Cross-compile Windows from WSL**: Use CMake with MinGW (see Quick Start section). Works reliably.

8. **NEVER invoke Windows executables from WSL.** Do NOT use `cmd.exe`, `powershell.exe`, or `GenerateProjects.bat` from WSL. This is stupid and doesn't work. Use CMake cross-compilation with MinGW instead, or tell the user to run Windows commands from a Windows terminal themselves.

9. **Current State (Dec 2025):**
   - Repository: https://github.com/suparious/minecraft.cpp
   - Latest release: **v1.2.0** (performance optimizations, cross-platform fixes)
   - Submodules point to official upstream repos (glfw/glfw, ocornut/imgui docking branch, etc.)
   - Premake build files in `VoxelEngine/vendor-build/` for Windows builds
   - MinGW cross-compile uses `-static` linking to avoid DLL dependencies

10. **WSL2 AMD Driver Bug:** The D3D12 OpenGL translation on WSL2 with AMD GPUs crashes in `amdxc64.so` (AMD shader compiler). This is a driver bug, not fixable in code. Workarounds:
    - Use software rendering (llvmpipe) - slow but works
    - Build natively on Windows instead of WSL2
    - ImGui is disabled on Linux to avoid related crashes

11. **ImGui Compatibility:** The docking branch (Dec 2025) has `ImGuiBackendFlags_RendererHasTextures` for dynamic font atlas. This crashes on WSL2's D3D12 layer. ImGui layer is conditionally disabled on Linux in `Application.cpp`.

12. **Release Workflow:** Use `./release.sh v1.x.x` to build both Windows and Linux packages. Creates zip/tarball in `releases/` directory. Then use `gh release create` to publish to GitHub.

**Trust but verify. Don't make changes you can't justify with evidence from the codebase.**

---

**Last Updated**: December 19, 2025 (v1.2.0 release)
