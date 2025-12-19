#pragma once

#include <glad/glad.h>
#include <string>
#include <unordered_map>
#include <vector>

namespace VoxelEngine {

// GPU profiler using OpenGL timer queries
// Usage:
//   GpuProfiler::Get().BeginFrame();
//   GpuProfiler::Get().BeginQuery("generateQuads");
//   glDispatchCompute(...);
//   GpuProfiler::Get().EndQuery("generateQuads");
//   GpuProfiler::Get().EndFrame();
//   float ms = GpuProfiler::Get().GetTimeMs("generateQuads");

class GpuProfiler {
public:
    static GpuProfiler& Get() {
        static GpuProfiler instance;
        return instance;
    }

    void Init() {
        if (m_Initialized) return;
        m_Initialized = true;

        // Check if timer queries are supported
        GLint numExtensions;
        glGetIntegerv(GL_NUM_EXTENSIONS, &numExtensions);
        m_Supported = true; // Timer queries are core in OpenGL 3.3+
    }

    void BeginFrame() {
        if (!m_Supported) return;

        // Collect results from previous frame (queries should be ready by now)
        for (auto& [name, data] : m_Queries) {
            if (data.queryActive && data.queryId != 0) {
                GLuint64 elapsedTime = 0;
                glGetQueryObjectui64v(data.queryId, GL_QUERY_RESULT, &elapsedTime);
                data.lastTimeNs = elapsedTime;
                // Exponential moving average for smoother display
                data.avgTimeNs = data.avgTimeNs * 0.9f + elapsedTime * 0.1f;
                data.queryActive = false;
            }
        }
        m_CurrentFrame++;
    }

    void EndFrame() {
        // Called after all queries for the frame
    }

    void BeginQuery(const std::string& name) {
        if (!m_Supported) return;

        auto& data = GetOrCreateQuery(name);
        if (data.queryId == 0) {
            glGenQueries(1, &data.queryId);
        }
        glBeginQuery(GL_TIME_ELAPSED, data.queryId);
    }

    void EndQuery(const std::string& name) {
        if (!m_Supported) return;

        glEndQuery(GL_TIME_ELAPSED);
        m_Queries[name].queryActive = true;
    }

    // Get timing in milliseconds
    float GetTimeMs(const std::string& name) const {
        auto it = m_Queries.find(name);
        if (it == m_Queries.end()) return 0.0f;
        return it->second.lastTimeNs / 1000000.0f;
    }

    float GetAvgTimeMs(const std::string& name) const {
        auto it = m_Queries.find(name);
        if (it == m_Queries.end()) return 0.0f;
        return static_cast<float>(it->second.avgTimeNs / 1000000.0);
    }

    // Get all query names for iteration
    std::vector<std::string> GetQueryNames() const {
        std::vector<std::string> names;
        names.reserve(m_Queries.size());
        for (const auto& [name, _] : m_Queries) {
            names.push_back(name);
        }
        return names;
    }

    float GetTotalFrameTimeMs() const {
        float total = 0.0f;
        for (const auto& [_, data] : m_Queries) {
            total += data.lastTimeNs / 1000000.0f;
        }
        return total;
    }

    bool IsSupported() const { return m_Supported; }

private:
    GpuProfiler() = default;
    ~GpuProfiler() {
        for (auto& [_, data] : m_Queries) {
            if (data.queryId != 0) {
                glDeleteQueries(1, &data.queryId);
            }
        }
    }

    struct QueryData {
        GLuint queryId = 0;
        bool queryActive = false;
        uint64_t lastTimeNs = 0;
        double avgTimeNs = 0.0;
    };

    QueryData& GetOrCreateQuery(const std::string& name) {
        auto it = m_Queries.find(name);
        if (it == m_Queries.end()) {
            m_Queries[name] = QueryData{};
        }
        return m_Queries[name];
    }

    std::unordered_map<std::string, QueryData> m_Queries;
    bool m_Initialized = false;
    bool m_Supported = false;
    uint64_t m_CurrentFrame = 0;
};

// RAII helper for scoped GPU profiling
class GpuProfileScope {
public:
    GpuProfileScope(const std::string& name) : m_Name(name) {
        GpuProfiler::Get().BeginQuery(name);
    }
    ~GpuProfileScope() {
        GpuProfiler::Get().EndQuery(m_Name);
    }
private:
    std::string m_Name;
};

#define VE_GPU_PROFILE_SCOPE(name) ::VoxelEngine::GpuProfileScope _gpuScope##__LINE__(name)

} // namespace VoxelEngine
