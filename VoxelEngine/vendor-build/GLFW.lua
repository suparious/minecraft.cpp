-- Premake build file for GLFW (submodule)
-- Source files are in ../vendor/GLFW/

project "GLFW"
	kind "StaticLib"
	language "C"
	staticruntime "on"

	targetdir ("bin/" .. outputdir .. "/%{prj.name}")
	objdir ("bin-int/" .. outputdir .. "/%{prj.name}")

	files
	{
		"../vendor/GLFW/include/GLFW/glfw3.h",
		"../vendor/GLFW/include/GLFW/glfw3native.h",
		"../vendor/GLFW/src/internal.h",
		"../vendor/GLFW/src/platform.h",
		"../vendor/GLFW/src/mappings.h",
		"../vendor/GLFW/src/context.c",
		"../vendor/GLFW/src/init.c",
		"../vendor/GLFW/src/input.c",
		"../vendor/GLFW/src/monitor.c",
		"../vendor/GLFW/src/platform.c",
		"../vendor/GLFW/src/vulkan.c",
		"../vendor/GLFW/src/window.c",
		"../vendor/GLFW/src/egl_context.c",
		"../vendor/GLFW/src/osmesa_context.c",
		"../vendor/GLFW/src/null_platform.h",
		"../vendor/GLFW/src/null_joystick.h",
		"../vendor/GLFW/src/null_init.c",
		"../vendor/GLFW/src/null_monitor.c",
		"../vendor/GLFW/src/null_window.c",
		"../vendor/GLFW/src/null_joystick.c"
	}

	filter "system:windows"
		systemversion "latest"

		files
		{
			"../vendor/GLFW/src/win32_init.c",
			"../vendor/GLFW/src/win32_module.c",
			"../vendor/GLFW/src/win32_joystick.c",
			"../vendor/GLFW/src/win32_monitor.c",
			"../vendor/GLFW/src/win32_time.h",
			"../vendor/GLFW/src/win32_time.c",
			"../vendor/GLFW/src/win32_thread.h",
			"../vendor/GLFW/src/win32_thread.c",
			"../vendor/GLFW/src/win32_window.c",
			"../vendor/GLFW/src/wgl_context.c",
		}

		defines
		{
			"_GLFW_WIN32",
			"_CRT_SECURE_NO_WARNINGS"
		}
	filter "configurations:Debug"
		runtime "Debug"
		symbols "on"
	filter "configurations:Release"
		runtime "Release"
		optimize "on"
