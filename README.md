# VoxelEngine - GPU-Accelerated Minecraft Clone

A high-performance voxel engine built with C++23 and OpenGL 4.3+ compute shaders, capable of rendering 10+ million TNT entities with physics simulation.

![Explosions in action](https://raw.githubusercontent.com/suparious/minecraft.cpp/refs/heads/main/doc/explosions_started.png)

## Features

- **GPU-accelerated terrain** - Compute shaders for world generation and mesh building
- **Greedy meshing** - Optimized quad generation for efficient rendering
- **10M+ entity physics** - TNT blocks with explosion propagation
- **Ambient occlusion** - Per-vertex AO for realistic lighting
- **Distance fog** - Atmospheric fog (150-400 block fade)
- **Block interaction** - Place and break blocks with raycast selection
- **Perlin noise terrain** - Heightmap-based hills and valleys
- **First-person controls** - WASD movement + mouse look

## Quick Start

### Windows (Visual Studio 2022)

```bash
# Clone with submodules
git clone --recursive https://github.com/suparious/minecraft.cpp.git
cd minecraft.cpp

# Generate Visual Studio solution
GenerateProjects.bat

# Open VoxelEngine.sln, build with F7, run
```

### Linux (Native CMake)

```bash
# Install dependencies (Ubuntu/Debian)
sudo apt install build-essential cmake libglfw3-dev libgl1-mesa-dev \
    libx11-dev libxrandr-dev libxi-dev libxxf86vm-dev libasound2-dev

# Clone and build
git clone --recursive https://github.com/suparious/minecraft.cpp.git
cd minecraft.cpp
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)

# Run (from build directory)
./bin/MinecraftClone
```

### Cross-Compile for Windows (from Linux/WSL)

```bash
# Install MinGW
sudo apt install mingw-w64

# Build
mkdir build-windows && cd build-windows
cmake .. \
    -DCMAKE_SYSTEM_NAME=Windows \
    -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc \
    -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ \
    -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)

# Output: bin/MinecraftClone.exe (run on Windows)
```

## Controls

| Key | Action |
|-----|--------|
| WASD | Move |
| Mouse | Look around |
| Space | Move up |
| Shift | Move down |
| Left Click | Break block / Activate TNT |
| Right Click | Place block |
| 1-9 | Select hotbar slot |
| F1/F2/F3 | Movement speed (slow/normal/fast) |
| ESC | Release mouse |

## Configuration

Edit `MinecraftClone/src/Layers/GameConfig.h`:

```cpp
constexpr int WORLD_WIDTH = 35;           // Chunks in X/Z (lower for less VRAM)
constexpr int WORLD_HEIGHT = 20;          // Chunks in Y
constexpr int HOW_MANY_TNT_TO_SPAWN = 10'000'000;  // Lower for testing
```

**Performance Tips:**
- Lower `WORLD_WIDTH` to 25 if you run out of GPU memory
- Lower `HOW_MANY_TNT_TO_SPAWN` to 100,000 for testing

## Platform Notes

### WSL2 (Windows Subsystem for Linux)

WSL2 has limited GPU support. Known issues:

- **AMD GPUs**: The D3D12 OpenGL translation layer may crash due to driver bugs in `amdxc64.so`. Use software rendering as a workaround:
  ```bash
  # Software rendering (slow but stable)
  ./bin/MinecraftClone

  # Hardware rendering (may crash on AMD)
  GALLIUM_DRIVER=d3d12 ./bin/MinecraftClone
  ```

- **Debug UI disabled**: ImGui is disabled on Linux due to compatibility issues with WSL2's D3D12 layer.

### Native Linux

For best performance on native Linux:
- Use proprietary GPU drivers (NVIDIA, AMD AMDGPU-PRO)
- Ensure OpenGL 4.3+ support with compute shaders

## Texture Packs

The project uses the [Bare Bones](https://modrinth.com/resourcepack/bare-bones) texture pack by default.

To use a different texture pack:
1. Delete `MinecraftClone/assets/textures/texture_pack/assets/`
2. Extract your texture pack's `assets/` folder to that location

## Building Releases

To build release packages for both Windows and Linux:

```bash
./release.sh v1.2.0
```

This creates:
- `releases/minecraft.cpp-v1.2.0-windows.zip` - Windows executable + assets
- `releases/minecraft.cpp-v1.2.0-linux.tar.gz` - Linux executable + assets

Pre-built binaries are available on the [Releases page](https://github.com/suparious/minecraft.cpp/releases).

## Build Configurations

| Config | Use Case |
|--------|----------|
| Debug | Development with OpenGL error logging |
| Release | Optimized with some debug symbols |
| Dist | Maximum performance, no debug overhead |

## Requirements

- **Windows**: Visual Studio 2022 with C++ Desktop Development
- **Linux**: GCC 12+ or Clang 15+ with C++23 support
- **GPU**: OpenGL 4.3+ with compute shader support
- **VRAM**: 4GB+ recommended for default world size

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Black screen | Check console for shader compilation errors |
| Crash on startup | Lower `WORLD_WIDTH` or `HOW_MANY_TNT_TO_SPAWN` |
| Missing textures | Ensure `assets/` folder is in the working directory |
| DLL errors (Windows) | Use the release build or build from source |

## License

This project is available under the MIT License.

## Acknowledgments

- [Bare Bones](https://modrinth.com/resourcepack/bare-bones) texture pack
- [GLFW](https://www.glfw.org/), [GLAD](https://glad.dav1d.de/), [GLM](https://github.com/g-truc/glm), [ImGui](https://github.com/ocornut/imgui), [spdlog](https://github.com/gabime/spdlog), [stb_image](https://github.com/nothings/stb), [raudio](https://github.com/raysan5/raudio)
