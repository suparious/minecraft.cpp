#pragma once
#include <VoxelEngine.h>
#include <imgui.h>
class DebugOverlay : public VoxelEngine::Layer {
public:
    DebugOverlay();

    ~DebugOverlay();
    virtual void OnAttach() override;
    virtual void OnDetach() override;
    virtual void OnUpdate(VoxelEngine::Timestep ts) override;
    virtual void OnImGuiRender() override;
    virtual void OnEvent(VoxelEngine::Event& event) override;

private:
    bool m_Visible = false;
    float m_FrameTime = 0.0f;
    float m_FrameTimeAccum = 0.0f;
    int m_FrameCount = 0;
    float m_AvgFrameTime = 0.0f;
};
