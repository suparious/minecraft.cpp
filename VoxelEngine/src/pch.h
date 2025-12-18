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
#include <tracy/Tracy.hpp>

#ifdef VE_PLATFORM_WINDOWS
    #ifdef _MSC_VER
        #include <Windows.h>
    #else
        // MinGW uses lowercase
        #include <windows.h>
    #endif
#endif
