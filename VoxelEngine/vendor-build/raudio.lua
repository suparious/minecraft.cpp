-- Premake build file for raudio (submodule)
-- Source files are in ../vendor/raudio/

project "raudio"
	kind "StaticLib"
	language "C"
	staticruntime "on"

	targetdir ("bin/" .. outputdir .. "/%{prj.name}")
	objdir ("bin-int/" .. outputdir .. "/%{prj.name}")

	files
	{
		"../vendor/raudio/src/*.c",
		"../vendor/raudio/src/*.h",
		"../vendor/raudio/src/external/*.h"
	}

	filter "system:windows"
		systemversion "latest"
		defines{ "RAUDIO_STANDALONE" }
	filter "configurations:Debug"
		runtime "Debug"
		symbols "on"
	filter "configurations:Release"
		runtime "Release"
		optimize "on"
