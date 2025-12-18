cmake_minimum_required(VERSION 3.20)
project(VoxelEngine VERSION 1.0.0 LANGUAGES C CXX)

# C++23 standard required
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 11)

# Output directories
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# Build type defaults to Release
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

# Platform detection
if(WIN32)
    add_compile_definitions(VE_PLATFORM_WINDOWS)
elseif(UNIX AND NOT APPLE)
    add_compile_definitions(VE_PLATFORM_LINUX)
elseif(APPLE)
    add_compile_definitions(VE_PLATFORM_MACOS)
endif()

# Build configuration defines
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_compile_definitions(VE_DEBUG)
elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
    add_compile_definitions(VE_RELEASE)
else()
    add_compile_definitions(VE_DIST)
endif()

# Find required packages (platform-specific)
if(WIN32)
    # Windows: OpenGL is linked directly as opengl32
    set(OPENGL_LIBRARIES opengl32)
else()
    find_package(OpenGL REQUIRED)
    set(OPENGL_LIBRARIES OpenGL::GL)
endif()

find_package(Threads REQUIRED)

# Linux-specific packages
if(UNIX AND NOT APPLE)
    find_package(X11 REQUIRED)
endif()

# ==============================================================================
# GLFW (has its own CMakeLists.txt)
# ==============================================================================
set(GLFW_BUILD_DOCS OFF CACHE BOOL "" FORCE)
set(GLFW_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(GLFW_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(GLFW_INSTALL OFF CACHE BOOL "" FORCE)
add_subdirectory(VoxelEngine/vendor/GLFW)

# ==============================================================================
# GLAD (OpenGL loader)
# ==============================================================================
add_library(glad STATIC
    VoxelEngine/vendor/GLAD/src/glad.c
)
target_include_directories(glad PUBLIC
    VoxelEngine/vendor/GLAD/include
)

# ==============================================================================
# ImGui
# ==============================================================================
add_library(imgui STATIC
    VoxelEngine/vendor/imgui/imgui.cpp
    VoxelEngine/vendor/imgui/imgui_demo.cpp
    VoxelEngine/vendor/imgui/imgui_draw.cpp
    VoxelEngine/vendor/imgui/imgui_tables.cpp
    VoxelEngine/vendor/imgui/imgui_widgets.cpp
    # Backends
    VoxelEngine/vendor/imgui/backends/imgui_impl_glfw.cpp
    VoxelEngine/vendor/imgui/backends/imgui_impl_opengl3.cpp
)
target_include_directories(imgui PUBLIC
    VoxelEngine/vendor/imgui
    VoxelEngine/vendor/imgui/backends
    VoxelEngine/vendor/GLFW/include
)
target_link_libraries(imgui PRIVATE glfw)

# ==============================================================================
# raudio (from raylib)
# ==============================================================================
add_library(raudio STATIC
    VoxelEngine/vendor/raudio/src/raudio.c
)
target_include_directories(raudio PUBLIC
    VoxelEngine/vendor/raudio/src
)
# raudio needs these defines
target_compile_definitions(raudio PRIVATE
    RAUDIO_STANDALONE
    SUPPORT_MODULE_RAUDIO
    SUPPORT_FILEFORMAT_WAV
    SUPPORT_FILEFORMAT_OGG
    SUPPORT_FILEFORMAT_MP3
)
if(WIN32)
    # Windows audio backend (DirectSound/WASAPI via miniaudio)
    target_link_libraries(raudio PRIVATE winmm ole32)
elseif(UNIX)
    # Linux audio backends (ALSA)
    find_library(ALSA_LIBRARY asound)
    if(ALSA_LIBRARY)
        target_link_libraries(raudio PRIVATE ${ALSA_LIBRARY})
    endif()
endif()

# ==============================================================================
# Tracy (profiler)
# ==============================================================================
option(TRACY_ENABLE "Enable Tracy profiler" OFF)
if(TRACY_ENABLE)
    add_library(tracy STATIC
        VoxelEngine/vendor/tracy/public/TracyClient.cpp
    )
    target_include_directories(tracy PUBLIC VoxelEngine/vendor/tracy/public)
    if(WIN32)
        target_link_libraries(tracy PRIVATE ws2_32 dbghelp)
    endif()
else()
    # When disabled, just provide headers (macros become no-ops)
    add_library(tracy INTERFACE)
    target_include_directories(tracy INTERFACE VoxelEngine/vendor/tracy/public)
    target_compile_definitions(tracy INTERFACE TRACY_ENABLE=0)
endif()

# ==============================================================================
# VoxelEngine (static library)
# ==============================================================================
file(GLOB_RECURSE VOXEL_ENGINE_SOURCES
    VoxelEngine/src/*.cpp
    VoxelEngine/src/*.h
)

# stb_image
list(APPEND VOXEL_ENGINE_SOURCES
    VoxelEngine/vendor/stb_image/stb_image.cpp
)

add_library(VoxelEngine STATIC ${VOXEL_ENGINE_SOURCES})

target_include_directories(VoxelEngine PUBLIC
    VoxelEngine/src
    VoxelEngine/vendor/spdlog/include
    VoxelEngine/vendor/GLFW/include
    VoxelEngine/vendor/GLAD/include
    VoxelEngine/vendor/imgui
    VoxelEngine/vendor/imgui/backends
    VoxelEngine/vendor/glm
    VoxelEngine/vendor/stb_image
    VoxelEngine/vendor/tracy/public
    VoxelEngine/vendor/raudio/src
)

target_link_libraries(VoxelEngine PUBLIC
    glfw
    glad
    imgui
    tracy
    raudio
    ${OPENGL_LIBRARIES}
    Threads::Threads
    ${CMAKE_DL_LIBS}
)

# Platform-specific libraries
if(WIN32)
    target_link_libraries(VoxelEngine PUBLIC
        gdi32
        winmm
        imm32
        ole32
        oleaut32
        uuid
        version
    )
elseif(UNIX AND NOT APPLE)
    target_link_libraries(VoxelEngine PUBLIC
        ${X11_LIBRARIES}
    )
endif()

target_compile_definitions(VoxelEngine PRIVATE
    GLFW_INCLUDE_NONE
    _CRT_SECURE_NO_WARNINGS
)

# Precompiled header (CMake 3.16+)
if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.16")
    target_precompile_headers(VoxelEngine PRIVATE VoxelEngine/src/pch.h)
endif()

# ==============================================================================
# MinecraftClone (executable)
# ==============================================================================
file(GLOB_RECURSE MINECRAFT_CLONE_SOURCES
    MinecraftClone/src/*.cpp
    MinecraftClone/src/*.h
)

add_executable(MinecraftClone ${MINECRAFT_CLONE_SOURCES})

target_include_directories(MinecraftClone PRIVATE
    VoxelEngine/src
    VoxelEngine/vendor/spdlog/include
    VoxelEngine/vendor/imgui
    VoxelEngine/vendor/imgui/backends
    VoxelEngine/vendor/glm
    VoxelEngine/vendor/tracy/public
    VoxelEngine/vendor/GLAD/include
    VoxelEngine/vendor/raudio/src
)

target_link_libraries(MinecraftClone PRIVATE
    VoxelEngine
    raudio
    m
)

# ==============================================================================
# Post-build: Copy assets to output directory
# ==============================================================================
add_custom_command(TARGET MinecraftClone POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${CMAKE_SOURCE_DIR}/MinecraftClone/assets
        ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/assets
    COMMENT "Copying assets to output directory"
)

# ==============================================================================
# Installation
# ==============================================================================
install(TARGETS MinecraftClone
    RUNTIME DESTINATION bin
)
install(DIRECTORY MinecraftClone/assets
    DESTINATION bin
)

# ==============================================================================
# Summary
# ==============================================================================
message(STATUS "")
message(STATUS "VoxelEngine Configuration Summary:")
message(STATUS "  Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "  C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "  Tracy profiler: ${TRACY_ENABLE}")
message(STATUS "  Platform: ${CMAKE_SYSTEM_NAME}")
message(STATUS "")
