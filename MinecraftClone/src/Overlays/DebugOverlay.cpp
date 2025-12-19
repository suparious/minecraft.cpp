#include "DebugOverlay.h"
#include "../Layers/GameLayer.h"
#include <VoxelEngine/Debug/GpuProfiler.h>

DebugOverlay::DebugOverlay()
{
}
DebugOverlay::~DebugOverlay()
{
}
void DebugOverlay::OnAttach()
{
}
void DebugOverlay::OnDetach()
{
}
void DebugOverlay::OnUpdate(VoxelEngine::Timestep ts)
{
    m_FrameTime = ts.GetMilliseconds();
    m_FrameTimeAccum += m_FrameTime;
    m_FrameCount++;
    if (m_FrameCount >= 30) {
        m_AvgFrameTime = m_FrameTimeAccum / m_FrameCount;
        m_FrameTimeAccum = 0.0f;
        m_FrameCount = 0;
    }
}
void DebugOverlay::OnImGuiRender()
{
    ImGuiIO& io = ImGui::GetIO();
    ImDrawList* drawList = ImGui::GetForegroundDrawList();

    // Always draw crosshair at screen center
    {
        float centerX = io.DisplaySize.x * 0.5f;
        float centerY = io.DisplaySize.y * 0.5f;
        float crosshairSize = 10.0f;
        float thickness = 2.0f;
        ImU32 color = IM_COL32(255, 255, 255, 200);  // White with slight transparency
        ImU32 outline = IM_COL32(0, 0, 0, 150);      // Black outline for visibility

        // Draw outline (slightly larger, black)
        drawList->AddLine(
            ImVec2(centerX - crosshairSize - 1, centerY),
            ImVec2(centerX + crosshairSize + 1, centerY),
            outline, thickness + 2.0f);
        drawList->AddLine(
            ImVec2(centerX, centerY - crosshairSize - 1),
            ImVec2(centerX, centerY + crosshairSize + 1),
            outline, thickness + 2.0f);

        // Draw crosshair (white)
        drawList->AddLine(
            ImVec2(centerX - crosshairSize, centerY),
            ImVec2(centerX + crosshairSize, centerY),
            color, thickness);
        drawList->AddLine(
            ImVec2(centerX, centerY - crosshairSize),
            ImVec2(centerX, centerY + crosshairSize),
            color, thickness);
    }

    // Draw hotbar at bottom of screen
    {
        GameLayer* gameLayer = VoxelEngine::Application::Get().GetLayer<GameLayer>();
        if (gameLayer) {
            const char* blockNames[] = {"Air", "Dirt", "Grass", "TNT", "Bedrock", "Stone"};
            int selectedSlot = gameLayer->GetSelectedHotbarSlot();

            float slotSize = 50.0f;
            float slotSpacing = 4.0f;
            float hotbarWidth = 9 * slotSize + 8 * slotSpacing;
            float hotbarX = (io.DisplaySize.x - hotbarWidth) * 0.5f;
            float hotbarY = io.DisplaySize.y - slotSize - 20.0f;

            // Block types in hotbar: dirt, grass, stone, bedrock, tnt, dirt, dirt, dirt, dirt
            uint32_t hotbarSlots[] = {1, 2, 5, 4, 3, 1, 1, 1, 1};

            for (int i = 0; i < 9; i++) {
                float slotX = hotbarX + i * (slotSize + slotSpacing);
                ImVec2 slotMin(slotX, hotbarY);
                ImVec2 slotMax(slotX + slotSize, hotbarY + slotSize);

                // Slot background
                ImU32 bgColor = (i == selectedSlot)
                    ? IM_COL32(100, 100, 100, 220)
                    : IM_COL32(40, 40, 40, 180);
                drawList->AddRectFilled(slotMin, slotMax, bgColor, 4.0f);

                // Slot border
                ImU32 borderColor = (i == selectedSlot)
                    ? IM_COL32(255, 255, 255, 255)
                    : IM_COL32(80, 80, 80, 200);
                drawList->AddRect(slotMin, slotMax, borderColor, 4.0f, 0, (i == selectedSlot) ? 3.0f : 1.0f);

                // Block name
                uint32_t blockType = hotbarSlots[i];
                const char* name = (blockType < 6) ? blockNames[blockType] : "?";
                ImVec2 textSize = ImGui::CalcTextSize(name);
                float textX = slotX + (slotSize - textSize.x) * 0.5f;
                float textY = hotbarY + (slotSize - textSize.y) * 0.5f;
                drawList->AddText(ImVec2(textX, textY), IM_COL32(255, 255, 255, 255), name);

                // Slot number
                char slotNum[2] = {(char)('1' + i), '\0'};
                drawList->AddText(ImVec2(slotX + 4, hotbarY + 2), IM_COL32(200, 200, 200, 180), slotNum);
            }
        }
    }

    // FPS counter (always visible in top-left)
    {
        float fps = m_AvgFrameTime > 0 ? 1000.0f / m_AvgFrameTime : 0.0f;
        char fpsText[64];
        snprintf(fpsText, sizeof(fpsText), "%.1f FPS (%.2f ms)", fps, m_AvgFrameTime);
        drawList->AddText(ImVec2(10, 10), IM_COL32(255, 255, 255, 255), fpsText);
    }

    // Debug menu (toggled with F3)
    if (m_Visible) {
        GameLayer* gameLayer = VoxelEngine::Application::Get().GetLayer<GameLayer>();
        if (gameLayer) {
            VoxelEngine::PerspectiveCamera camera = gameLayer->GetCamera();
            float cameraYaw = camera.GetYaw();
            glm::vec3 cameraPosition = camera.GetPosition();
            std::string directionLookingAt = "";
            if (cameraYaw >= -45.0f && cameraYaw < 45.0f) {
                directionLookingAt = "Facing: south (Towards positive Z)";
            } else if (cameraYaw >= 45.0f && cameraYaw < 135.0f) {
                directionLookingAt = "Facing: west (Towards negative X)";
            } else if (cameraYaw >= 135.0f || cameraYaw < -135.0f) {
                directionLookingAt = "Facing: north (Towards negative Z)";
            } else if (cameraYaw >= -135.0f && cameraYaw < 45.0f) {
                directionLookingAt = "Facing: east (Towards positive X)";
            }
            ImGui::Begin("Debug Menu");
            ImGui::Text("%s (%.1f / %.1f)", directionLookingAt.c_str(), camera.GetYaw(), camera.GetPitch());
            ImGui::Text("Position X:%.0f, Y:%.0f, Z:%.0f", cameraPosition.x, cameraPosition.y, cameraPosition.z);
            ImGui::End();
        }

        // GPU Profiler window
        auto& profiler = VoxelEngine::GpuProfiler::Get();
        if (profiler.IsSupported()) {
            ImGui::Begin("GPU Profiler");
            ImGui::Text("GPU Timings (avg ms):");
            ImGui::Separator();

            float totalGpuTime = 0.0f;
            auto queryNames = profiler.GetQueryNames();
            for (const auto& name : queryNames) {
                float avgMs = profiler.GetAvgTimeMs(name);
                totalGpuTime += avgMs;

                // Color code based on time
                ImVec4 color = ImVec4(0.0f, 1.0f, 0.0f, 1.0f);  // green
                if (avgMs > 5.0f) color = ImVec4(1.0f, 1.0f, 0.0f, 1.0f);  // yellow
                if (avgMs > 10.0f) color = ImVec4(1.0f, 0.0f, 0.0f, 1.0f);  // red

                ImGui::TextColored(color, "%-20s: %6.2f ms", name.c_str(), avgMs);
            }
            ImGui::Separator();
            ImGui::Text("Total GPU: %.2f ms", totalGpuTime);
            ImGui::End();
        }
    }
}
void DebugOverlay::OnEvent(VoxelEngine::Event& event)
{
    VoxelEngine::EventDispatcher dispatcher(event);
    dispatcher.Dispatch<VoxelEngine::KeyPressedEvent>([&](VoxelEngine::KeyPressedEvent& e) {
        if (e.GetKeyCode() == VE_KEY_F3) {
            m_Visible = !m_Visible;
            return true;
        }
        return false;
    });
    dispatcher.Dispatch<VoxelEngine::KeyPressedEvent>([&](VoxelEngine::KeyPressedEvent& e) {
        if (e.GetKeyCode() == VE_KEY_TAB) {
            VoxelEngine::Application::Get().GetWindow().ToggleCursorVisibility();
            return true;
        }
        return false;
    });
}
