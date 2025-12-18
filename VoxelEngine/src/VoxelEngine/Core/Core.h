#pragma once
#include <memory>

// Platform detection and API export macros
#ifdef VE_PLATFORM_WINDOWS
    #if VE_DYNAMIC_LINK
        #ifdef VE_BUILD_DLL
            #define VE_API __declspec(dllexport)
        #else
            #define VE_API __declspec(dllimport)
        #endif
    #else
        #define VE_API
    #endif
    #define VE_DEBUGBREAK() __debugbreak()
#elif defined(VE_PLATFORM_LINUX)
    #define VE_API
    #include <signal.h>
    #define VE_DEBUGBREAK() raise(SIGTRAP)
#elif defined(VE_PLATFORM_MACOS)
    #define VE_API
    #define VE_DEBUGBREAK() __builtin_trap()
#else
    #error "Unsupported platform! Define VE_PLATFORM_WINDOWS, VE_PLATFORM_LINUX, or VE_PLATFORM_MACOS"
#endif

#ifdef VE_DEBUG
#define VE_ENABLE_ASSERTS
#define TRACY_ENABLE
#endif

#ifdef VE_ENABLE_ASSERTS
#define VE_ASSERT(x, ...)                                   \
    {                                                       \
        if (!(x)) {                                         \
            VE_ERROR("Assertion Failed: {0}", __VA_ARGS__); \
            VE_DEBUGBREAK();                                \
        }                                                   \
    }
#define VE_CORE_ASSERT(x, ...)                                   \
    {                                                            \
        if (!(x)) {                                              \
            VE_CORE_ERROR("Assertion Failed: {0}", __VA_ARGS__); \
            VE_DEBUGBREAK();                                     \
        }                                                        \
    }
#else
#define VE_ASSERT(x, ...)
#define VE_CORE_ASSERT(x, ...)
#endif

#define BIT(x) (1 << x)

#define VE_BIND_EVENT_FN(fn) std::bind(&fn, this, std::placeholders::_1)

namespace VoxelEngine {
template <typename T>
using Scope = std::unique_ptr<T>;
template <typename T>
using Ref = std::shared_ptr<T>;
typedef unsigned char texture_data;
template <typename T, typename... Args>
constexpr Ref<T> CreateRef(Args&&... args)
{
    return std::make_shared<T>(std::forward<Args>(args)...);
}
template <typename T, typename... Args>
constexpr Scope<T> CreateScope(Args&&... args)
{
    return std::make_unique<T>(std::forward<Args>(args)...);
}
} // namespace VoxelEngine
#define GLM_ENABLE_EXPERIMENTAL
