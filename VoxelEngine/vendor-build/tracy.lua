-- Premake build file for Tracy Profiler (submodule)
-- Source files are in ../vendor/tracy/

project "tracy"
	kind "StaticLib"
	language "C++"
	cppdialect "C++11"
	staticruntime "on"

	targetdir ("bin/" .. outputdir .. "/%{prj.name}")
	objdir ("bin-int/" .. outputdir .. "/%{prj.name}")

	files
	{
		-- Tracy public headers
		"../vendor/tracy/public/tracy/TracyC.h",
		"../vendor/tracy/public/tracy/Tracy.hpp",
		"../vendor/tracy/public/tracy/TracyD3D11.hpp",
		"../vendor/tracy/public/tracy/TracyD3D12.hpp",
		"../vendor/tracy/public/tracy/TracyLua.hpp",
		"../vendor/tracy/public/tracy/TracyOpenCL.hpp",
		"../vendor/tracy/public/tracy/TracyOpenGL.hpp",
		"../vendor/tracy/public/tracy/TracyVulkan.hpp",

		-- Tracy client headers
		"../vendor/tracy/public/client/**.h",
		"../vendor/tracy/public/client/**.hpp",

		-- Tracy common headers
		"../vendor/tracy/public/common/**.h",
		"../vendor/tracy/public/common/**.hpp",

		-- Tracy client source
		"../vendor/tracy/public/TracyClient.cpp"
	}

	filter "system:windows"
		systemversion "latest"
		links { "ws2_32", "dbghelp" }
	filter "configurations:Debug"
		runtime "Debug"
		defines { "TRACY_ENABLE" }
		symbols "on"
	filter "configurations:Release"
		runtime "Release"
		optimize "on"
