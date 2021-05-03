#pragma once
#include "imgui.h"
#include "imgui_impl_win32.h"
#include "imgui_impl_dx11.h"

struct DebugConsole {
public:
	void AddLog(const char* fmt, ...) IM_FMTARGS(2);
	DebugConsole();
	~DebugConsole();
	void ClearLog();
	void Draw(const char* title, bool* p_open);
	void    ExecCommand(const char* command_line);
	/*static int TextEditCallbackStub(ImGuiInputTextCallbackData* data);*/
	int     TextEditCallback(ImGuiInputTextCallbackData* data);
};
