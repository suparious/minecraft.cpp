-- Premake build file for Dear ImGui (submodule)
-- Source files are in ../vendor/imgui/

project "ImGui"
	kind "StaticLib"
	language "C++"
	cppdialect "C++17"
	staticruntime "on"

	targetdir ("bin/" .. outputdir .. "/%{prj.name}")
	objdir ("bin-int/" .. outputdir .. "/%{prj.name}")

	files
	{
		"../vendor/imgui/imconfig.h",
		"../vendor/imgui/imgui.h",
		"../vendor/imgui/imgui.cpp",
		"../vendor/imgui/imgui_draw.cpp",
		"../vendor/imgui/imgui_internal.h",
		"../vendor/imgui/imgui_widgets.cpp",
		"../vendor/imgui/imgui_tables.cpp",
		"../vendor/imgui/imstb_rectpack.h",
		"../vendor/imgui/imstb_textedit.h",
		"../vendor/imgui/imstb_truetype.h",
		"../vendor/imgui/imgui_demo.cpp"
	}

	filter "system:windows"
		systemversion "latest"
	filter "configurations:Debug"
		runtime "Debug"
		symbols "on"
	filter "configurations:Release"
		runtime "Release"
		optimize "on"
