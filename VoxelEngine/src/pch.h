#pragma once

#include <iostream>
#include <memory>
#include <utility>
#include <algorithm>
#include <functional>

#include <string>
#include <sstream>
#include <vector>
#include <array>
#include <unordered_map>
#include <unordered_set>
#include "VoxelEngine/Core/Log.h"
#include "VoxelEngine/Debug/Instrumentor.h"
#include <regex>
// Tracy profiler - only include when explicitly enabled
// Tracy checks if TRACY_ENABLE is *defined*, not its value
#if defined(TRACY_ENABLE) && TRACY_ENABLE
#include <tracy/Tracy.hpp>
#else
// Stub out Tracy macros when profiler is disabled
#define ZoneScoped
#define ZoneScopedN(x)
#define ZoneScopedC(x)
#define ZoneScopedNC(x,y)
#define ZoneText(x,y)
#define ZoneName(x,y)
#define TracyPlot(x,y)
#define TracyMessage(x,y)
#define TracyMessageL(x)
#define TracyAlloc(x,y)
#define TracyFree(x)
#define FrameMark
#define FrameMarkNamed(x)
#define FrameMarkStart(x)
#define FrameMarkEnd(x)
#endif

#ifdef VE_PLATFORM_WINDOWS
    #ifdef _MSC_VER
        #include <Windows.h>
    #else
        // MinGW uses lowercase
        #include <windows.h>
    #endif
#endif
