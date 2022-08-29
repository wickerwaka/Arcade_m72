// Dear ImGui: standalone example application for DirectX 11
// If you are new to Dear ImGui, read documentation from the docs/ folder + read the top of imgui.cpp.
// Read online: https://github.com/ocornut/imgui/tree/master/docs

#include "imgui.h"
#include "imgui_impl_win32.h"
#include "imgui_impl_dx11.h"
#include <d3d11.h>
#include <tchar.h>

#include "trace.h"
#include "imgui_memory_editor.h"

#include "capstone/capstone.h"

// Data
static ID3D11Device*            g_pd3dDevice = NULL;
static ID3D11DeviceContext*     g_pd3dDeviceContext = NULL;
static IDXGISwapChain*          g_pSwapChain = NULL;
static ID3D11RenderTargetView*  g_mainRenderTargetView = NULL;

// Forward declarations of helper functions
bool CreateDeviceD3D(HWND hWnd);
void CleanupDeviceD3D();
void CreateRenderTarget();
void CleanupRenderTarget();
LRESULT WINAPI WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);


// Static state data
static std::vector<TraceRecord> s_trace;
static int64_t s_trace_position = 0;
static uint8_t s_shared_mem[4096];
static int64_t s_trace_offset = 0;

static int64_t s_trace_scroll_target = -1;

static MemoryEditor mem_edit;

void trace_simulate_to(int64_t new_position)
{
    if (new_position < s_trace_position)
    {
        s_trace_position = 0;
        memset(s_shared_mem, 0, sizeof(s_shared_mem));
    }

    if (new_position >= s_trace.size()) new_position = s_trace.size() - 1;

    for (size_t pos = s_trace_position; pos <= new_position; pos++)
    {
        const TraceRecord& rec = s_trace[pos];

        switch (rec.type)
        {
        case CPU_MEM_WRITE:
            s_shared_mem[rec.cpu_write.address] = rec.cpu_write.value & 0xff;
            if( rec.cpu_write.size == 2) 
                s_shared_mem[rec.cpu_write.address + 1] = ( rec.cpu_write.value >> 8 ) & 0xff;
            break;

        case MCU_MEM_WRITE:
            s_shared_mem[rec.mcu_mem.address] = rec.mcu_mem.value;
            break;

        default:
            break;
        }
    }

    s_trace_position = new_position;
}

int64_t trace_find_mem_write(int64_t start, int direction, int address, bool mcu, bool cpu, bool read_op, bool write_op)
{
    int64_t pos = start + direction;

    while (pos >=0 && pos < s_trace.size())
    {
        const TraceRecord rec = s_trace[pos];
        switch (rec.type)
        {
        case CPU_MEM_WRITE:
            if (cpu && write_op && rec.cpu_write.address == address) return pos;
            break;
        case CPU_MEM_READ:
            if (cpu && read_op && rec.cpu_write.address == address) return pos;
            break;
        case MCU_MEM_WRITE:
            if (mcu && write_op && rec.mcu_mem.address == address) return pos;
            break;
        case MCU_MEM_READ:
            if (mcu && read_op && rec.mcu_mem.address == address) return pos;
            break;
        default:
            break;
        }

        pos += direction;
    }

    return -1;
}

int64_t trace_find_pc(int64_t start, int direction, int address, bool mcu, bool cpu)
{
    int64_t pos = start + direction;

    while (pos >= 0 && pos < s_trace.size())
    {
        const TraceRecord rec = s_trace[pos];
        switch (rec.type)
        {
        case CPU_IP:
            if (cpu && rec.cpu_ip.address == address) return pos;
            break;
        case MCU_ROM:
            if (mcu && rec.mcu_rom.address == address) return pos;
            break;
        default:
            break;
        }

        pos += direction;
    }

    return -1;
}

void draw_trace_view()
{
    float text_height = ImGui::GetTextLineHeightWithSpacing();
    int64_t slider_min = 0;
    int64_t slider_max = s_trace.size() > 1000000 ? s_trace.size() - 1000000 : 0;

    static int step_mem_address = 0;
    static bool step_mem_mcu = true;
    static bool step_mem_cpu = true;
    static bool step_mem_read = true;
    static bool step_mem_write = true;

    static int step_pc_address = 0;
    static bool step_pc_mcu = true;
    static bool step_pc_cpu = true;

    int64_t scroll_target = s_trace_scroll_target;

    if (scroll_target >= 0)
    {
        s_trace_offset = scroll_target - 500000;
        if (s_trace_offset < 0) s_trace_offset = 0;
    }

    ImGui::SliderScalar("Offset", ImGuiDataType_S64, &s_trace_offset, &slider_min, &slider_max);
    
    ImGui::PushID("memory_access");
    ImGui::Text("Access");
    ImGui::SetNextItemWidth(120);
    ImGui::SameLine(); ImGui::InputInt("AddrMem", &step_mem_address, 1, 100, ImGuiInputTextFlags_CharsHexadecimal);
    ImGui::SameLine(); ImGui::Checkbox("MCU", &step_mem_mcu);
    ImGui::SameLine(); ImGui::Checkbox("CPU", &step_mem_cpu);
    ImGui::SameLine(); ImGui::Checkbox("Read", &step_mem_read);
    ImGui::SameLine(); ImGui::Checkbox("Write", &step_mem_write);
    ImGui::SameLine();
    if (ImGui::Button("< Prev"))
    {
        int64_t pos = trace_find_mem_write(s_trace_position, -1, step_mem_address, step_mem_mcu, step_mem_cpu, step_mem_read, step_mem_write);
        if (pos >= 0)
        {
            trace_simulate_to(pos);
            s_trace_scroll_target = pos;
        }
    }

    ImGui::SameLine();
    
    if (ImGui::Button("Next >"))
    {
        int64_t pos = trace_find_mem_write(s_trace_position, 1, step_mem_address, step_mem_mcu, step_mem_cpu, step_mem_read, step_mem_write);
        if (pos >= 0)
        {
            trace_simulate_to(pos);
            s_trace_scroll_target = pos;
        }
    }
    ImGui::PopID();

    ImGui::PushID("pc");

    ImGui::Text("PC");
    ImGui::SetNextItemWidth(120);
    ImGui::SameLine(); ImGui::InputInt("AddrPC", &step_pc_address, 1, 100, ImGuiInputTextFlags_CharsHexadecimal);
    ImGui::SameLine(); ImGui::Checkbox("MCU", &step_pc_mcu);
    ImGui::SameLine(); ImGui::Checkbox("CPU", &step_pc_cpu);
    ImGui::SameLine();
    if (ImGui::Button("< Prev"))
    {
        int64_t pos = trace_find_pc(s_trace_position, -1, step_pc_address, step_pc_mcu, step_pc_cpu);
        if (pos >= 0)
        {
            trace_simulate_to(pos);
            s_trace_scroll_target = pos;
        }
    }

    ImGui::SameLine();

    if (ImGui::Button("Next >"))
    {
        int64_t pos = trace_find_pc(s_trace_position, 1, step_pc_address, step_pc_mcu, step_pc_cpu);
        if (pos >= 0)
        {
            trace_simulate_to(pos);
            s_trace_scroll_target = pos;
        }
    }
    ImGui::PopID();

    if (!ImGui::BeginTable("trace", 4, ImGuiTableFlags_ScrollY, ImVec2(0.0f, 0.0f))) return;

    ImGui::TableSetupScrollFreeze(0, 1); // Make top row always visible
    ImGui::TableSetupColumn("Id", ImGuiTableColumnFlags_None);
    ImGui::TableSetupColumn("Type", ImGuiTableColumnFlags_None);
    ImGui::TableSetupColumn("Address", ImGuiTableColumnFlags_None);
    ImGui::TableSetupColumn("Value", ImGuiTableColumnFlags_None);
    ImGui::TableHeadersRow();

    size_t trace_count = s_trace.size() - s_trace_offset;
    if (trace_count > 1000000) trace_count = 1000000;

    ImGuiListClipper clipper(trace_count);

    while (clipper.Step())
    {
        if (scroll_target != -1)
        {
            ImGui::SetScrollY(clipper.ItemsHeight * (scroll_target - s_trace_offset));
            s_trace_scroll_target = -1;
        }

        for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
        {
            int64_t real_i = i + s_trace_offset;

            ImGui::TableNextRow();
            ImGui::TableNextColumn();
            char index[16];
            sprintf(index, "%zd", real_i);

            
            if (ImGui::Selectable(index, real_i == s_trace_position, ImGuiSelectableFlags_SpanAllColumns))
            {
                trace_simulate_to(real_i);
            }

            ImGui::TableNextColumn();

            const TraceRecord& rec = s_trace[real_i];
            switch (rec.type)
            {
            case CPU_MEM_READ:
                ImGui::Text("CPU Read");
                ImGui::TableNextColumn();
                ImGui::Text("%03X", rec.cpu_read.address);
                ImGui::TableNextColumn();
                ImGui::Text("%04X", rec.cpu_read.value);
                break;
            case CPU_MEM_WRITE:
                ImGui::Text("CPU Write");
                ImGui::TableNextColumn();
                ImGui::Text("%03X", rec.cpu_write.address);
                ImGui::TableNextColumn();
                if (rec.cpu_write.size == 2)
                    ImGui::Text("%04X", rec.cpu_write.value);
                else
                    ImGui::Text("%02X", rec.cpu_write.value);
                break;
            case MCU_MEM_READ:
                ImGui::Text("MCU Read");
                ImGui::TableNextColumn();
                ImGui::Text("%03X", rec.mcu_mem.address);
                ImGui::TableNextColumn();
                ImGui::Text("%02X", rec.mcu_mem.value);
                break;

            case MCU_MEM_WRITE:
                ImGui::Text("MCU Write");
                ImGui::TableNextColumn();
                ImGui::Text("%03X", rec.mcu_mem.address);
                ImGui::TableNextColumn();
                ImGui::Text("%02X", rec.mcu_mem.value);
                break;

            case MCU_ROM:
                ImGui::Text("MCU ROM");
                ImGui::TableNextColumn();
                ImGui::Text("%04X", rec.mcu_rom.address);
                break;

            case CPU_IP:
                ImGui::Text("CPU IP");
                ImGui::TableNextColumn();
                ImGui::Text("%06X", rec.cpu_ip.address);
                ImGui::TableNextColumn();
                ImGui::Text("%02X", rec.cpu_ip.opcode);
                break;
            }
        }
    }

    ImGui::EndTable();
}

void draw_disassembly(uint32_t addr)
{
    const int LEN = 16;
    static char lines[LEN][256];
    static uint8_t data[LEN];

    if (memcmp(data, s_shared_mem + addr, LEN))
    {
        memcpy(data, s_shared_mem + addr, LEN);

        for (int i = 0; i < LEN; i++)
        {
            lines[i][0] = '\0';
        }

        csh handle;


        if (cs_open(CS_ARCH_X86, CS_MODE_16, &handle) == CS_ERR_OK)
        {
            cs_insn* insn;
            size_t count = cs_disasm(handle, data, LEN, 0xb0000 + addr, 0, &insn);
            if (count > 0)
            {
                for (size_t j = 0; j < count; j++)
                {
                    sprintf(lines[j], "0x%06x:\t%s\t\t%s\n", insn[j].address, insn[j].mnemonic,
                        insn[j].op_str);
                }
            }

            cs_free(insn, count);
            cs_close(&handle);
        }
    }
    ImGui::Begin("Disassembly");

    for (int i = 0; i < LEN; i++)
    {
        if (lines[i][0]) ImGui::Text(lines[i]);
    }

    ImGui::End();
}
// Main code
int main(int, char**)
{
    s_trace = read_trace("C:/Users/Martin/Source/Arcade_m72_v30/reverse_eng/nspirit/m72_trace.bin");

    // Create application window
    //ImGui_ImplWin32_EnableDpiAwareness();
    WNDCLASSEX wc = { sizeof(WNDCLASSEX), CS_CLASSDC, WndProc, 0L, 0L, GetModuleHandle(NULL), NULL, NULL, NULL, NULL, _T("ImGui Example"), NULL };
    ::RegisterClassEx(&wc);
    HWND hwnd = ::CreateWindow(wc.lpszClassName, _T("Dear ImGui DirectX11 Example"), WS_OVERLAPPEDWINDOW, 100, 100, 1280, 800, NULL, NULL, wc.hInstance, NULL);

    // Initialize Direct3D
    if (!CreateDeviceD3D(hwnd))
    {
        CleanupDeviceD3D();
        ::UnregisterClass(wc.lpszClassName, wc.hInstance);
        return 1;
    }

    // Show the window
    ::ShowWindow(hwnd, SW_SHOWDEFAULT);
    ::UpdateWindow(hwnd);

    // Setup Dear ImGui context
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    //io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;     // Enable Keyboard Controls
    //io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;      // Enable Gamepad Controls

    // Setup Dear ImGui style
    ImGui::StyleColorsDark();
    //ImGui::StyleColorsLight();

    // Setup Platform/Renderer backends
    ImGui_ImplWin32_Init(hwnd);
    ImGui_ImplDX11_Init(g_pd3dDevice, g_pd3dDeviceContext);

    // Load Fonts
    // - If no fonts are loaded, dear imgui will use the default font. You can also load multiple fonts and use ImGui::PushFont()/PopFont() to select them.
    // - AddFontFromFileTTF() will return the ImFont* so you can store it if you need to select the font among multiple.
    // - If the file cannot be loaded, the function will return NULL. Please handle those errors in your application (e.g. use an assertion, or display an error and quit).
    // - The fonts will be rasterized at a given size (w/ oversampling) and stored into a texture when calling ImFontAtlas::Build()/GetTexDataAsXXXX(), which ImGui_ImplXXXX_NewFrame below will call.
    // - Read 'docs/FONTS.md' for more instructions and details.
    // - Remember that in C/C++ if you want to include a backslash \ in a string literal you need to write a double backslash \\ !
    //io.Fonts->AddFontDefault();
    //io.Fonts->AddFontFromFileTTF("../../misc/fonts/Roboto-Medium.ttf", 16.0f);
    //io.Fonts->AddFontFromFileTTF("../../misc/fonts/Cousine-Regular.ttf", 15.0f);
    //io.Fonts->AddFontFromFileTTF("../../misc/fonts/DroidSans.ttf", 16.0f);
    //io.Fonts->AddFontFromFileTTF("../../misc/fonts/ProggyTiny.ttf", 10.0f);
    //ImFont* font = io.Fonts->AddFontFromFileTTF("c:\\Windows\\Fonts\\ArialUni.ttf", 18.0f, NULL, io.Fonts->GetGlyphRangesJapanese());
    //IM_ASSERT(font != NULL);

    // Our state
    ImVec4 clear_color = ImVec4(0.45f, 0.55f, 0.60f, 1.00f);

    // Main loop
    bool done = false;
    while (!done)
    {
        // Poll and handle messages (inputs, window resize, etc.)
        // See the WndProc() function below for our to dispatch events to the Win32 backend.
        MSG msg;
        while (::PeekMessage(&msg, NULL, 0U, 0U, PM_REMOVE))
        {
            ::TranslateMessage(&msg);
            ::DispatchMessage(&msg);
            if (msg.message == WM_QUIT)
                done = true;
        }
        if (done)
            break;

        // Start the Dear ImGui frame
        ImGui_ImplDX11_NewFrame();
        ImGui_ImplWin32_NewFrame();
        ImGui::NewFrame();

        ImGui::Begin("Trace");                          // Create a window called "Hello, world!" and append into it.

        draw_trace_view();
        ImGui::End();

        draw_disassembly(mem_edit.DataPreviewAddr < 0x1000 ? mem_edit.DataPreviewAddr : 0);

        mem_edit.DrawWindow("Memory Editor", s_shared_mem, 0x1000);

        // Rendering
        ImGui::Render();
        const float clear_color_with_alpha[4] = { clear_color.x * clear_color.w, clear_color.y * clear_color.w, clear_color.z * clear_color.w, clear_color.w };
        g_pd3dDeviceContext->OMSetRenderTargets(1, &g_mainRenderTargetView, NULL);
        g_pd3dDeviceContext->ClearRenderTargetView(g_mainRenderTargetView, clear_color_with_alpha);
        ImGui_ImplDX11_RenderDrawData(ImGui::GetDrawData());

        g_pSwapChain->Present(1, 0); // Present with vsync
        //g_pSwapChain->Present(0, 0); // Present without vsync
    }

    // Cleanup
    ImGui_ImplDX11_Shutdown();
    ImGui_ImplWin32_Shutdown();
    ImGui::DestroyContext();

    CleanupDeviceD3D();
    ::DestroyWindow(hwnd);
    ::UnregisterClass(wc.lpszClassName, wc.hInstance);

    return 0;
}

// Helper functions

bool CreateDeviceD3D(HWND hWnd)
{
    // Setup swap chain
    DXGI_SWAP_CHAIN_DESC sd;
    ZeroMemory(&sd, sizeof(sd));
    sd.BufferCount = 2;
    sd.BufferDesc.Width = 0;
    sd.BufferDesc.Height = 0;
    sd.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
    sd.BufferDesc.RefreshRate.Numerator = 60;
    sd.BufferDesc.RefreshRate.Denominator = 1;
    sd.Flags = DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH;
    sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    sd.OutputWindow = hWnd;
    sd.SampleDesc.Count = 1;
    sd.SampleDesc.Quality = 0;
    sd.Windowed = TRUE;
    sd.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;

    UINT createDeviceFlags = 0;
    //createDeviceFlags |= D3D11_CREATE_DEVICE_DEBUG;
    D3D_FEATURE_LEVEL featureLevel;
    const D3D_FEATURE_LEVEL featureLevelArray[2] = { D3D_FEATURE_LEVEL_11_0, D3D_FEATURE_LEVEL_10_0, };
    if (D3D11CreateDeviceAndSwapChain(NULL, D3D_DRIVER_TYPE_HARDWARE, NULL, createDeviceFlags, featureLevelArray, 2, D3D11_SDK_VERSION, &sd, &g_pSwapChain, &g_pd3dDevice, &featureLevel, &g_pd3dDeviceContext) != S_OK)
        return false;

    CreateRenderTarget();
    return true;
}

void CleanupDeviceD3D()
{
    CleanupRenderTarget();
    if (g_pSwapChain) { g_pSwapChain->Release(); g_pSwapChain = NULL; }
    if (g_pd3dDeviceContext) { g_pd3dDeviceContext->Release(); g_pd3dDeviceContext = NULL; }
    if (g_pd3dDevice) { g_pd3dDevice->Release(); g_pd3dDevice = NULL; }
}

void CreateRenderTarget()
{
    ID3D11Texture2D* pBackBuffer;
    g_pSwapChain->GetBuffer(0, IID_PPV_ARGS(&pBackBuffer));
    g_pd3dDevice->CreateRenderTargetView(pBackBuffer, NULL, &g_mainRenderTargetView);
    pBackBuffer->Release();
}

void CleanupRenderTarget()
{
    if (g_mainRenderTargetView) { g_mainRenderTargetView->Release(); g_mainRenderTargetView = NULL; }
}

// Forward declare message handler from imgui_impl_win32.cpp
extern IMGUI_IMPL_API LRESULT ImGui_ImplWin32_WndProcHandler(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);

// Win32 message handler
// You can read the io.WantCaptureMouse, io.WantCaptureKeyboard flags to tell if dear imgui wants to use your inputs.
// - When io.WantCaptureMouse is true, do not dispatch mouse input data to your main application, or clear/overwrite your copy of the mouse data.
// - When io.WantCaptureKeyboard is true, do not dispatch keyboard input data to your main application, or clear/overwrite your copy of the keyboard data.
// Generally you may always pass all inputs to dear imgui, and hide them from your application based on those two flags.
LRESULT WINAPI WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    if (ImGui_ImplWin32_WndProcHandler(hWnd, msg, wParam, lParam))
        return true;

    switch (msg)
    {
    case WM_SIZE:
        if (g_pd3dDevice != NULL && wParam != SIZE_MINIMIZED)
        {
            CleanupRenderTarget();
            g_pSwapChain->ResizeBuffers(0, (UINT)LOWORD(lParam), (UINT)HIWORD(lParam), DXGI_FORMAT_UNKNOWN, 0);
            CreateRenderTarget();
        }
        return 0;
    case WM_SYSCOMMAND:
        if ((wParam & 0xfff0) == SC_KEYMENU) // Disable ALT application menu
            return 0;
        break;
    case WM_DESTROY:
        ::PostQuitMessage(0);
        return 0;
    }
    return ::DefWindowProc(hWnd, msg, wParam, lParam);
}
