#include <verilated.h>
#include "Vtop.h"

#include "imgui.h"
#include "implot.h"
#ifndef _MSC_VER
#include <stdio.h>
#include <SDL.h>
#include <SDL_opengl.h>
#else
#define WIN32
#include <dinput.h>
#endif

#include "sim_console.h"
#include "sim_bus.h"
#include "sim_video.h"
#include "sim_audio.h"
#include "sim_input.h"
#include "sim_clock.h"

#include "../imgui/imgui_memory_editor.h"
#include <verilated_vcd_c.h> //VCD Trace
#include "../imgui/ImGuiFileDialog.h"

#include <iostream>
#include <fstream>
using namespace std;

// Simulation control
// ------------------
int initialReset = 48;
bool run_enable = 1;
int batchSize = 150000;
bool single_step = 0;
bool multi_step = 0;
int multi_step_amount = 1024;

// Debug GUI 
// ---------
const char* windowTitle = "Verilator Sim: Arcade-Centipede";
const char* windowTitle_Control = "Simulation control";
const char* windowTitle_DebugLog = "Debug log";
const char* windowTitle_Video = "VGA output";
const char* windowTitle_Trace = "Trace/VCD control";
const char* windowTitle_Audio = "Audio output";
bool showDebugLog = true;
DebugConsole console;
MemoryEditor mem_edit;

// HPS emulator
// ------------
SimBus bus(console);

// Input handling
// --------------
SimInput input(12, console);
const int input_right = 0;
const int input_left = 1;
const int input_down = 2;
const int input_up = 3;
const int input_fire1 = 4;
const int input_fire2 = 5;
const int input_start_1 = 6;
const int input_start_2 = 7;
const int input_coin_1 = 8;
const int input_coin_2 = 9;
const int input_coin_3 = 10;
const int input_pause = 11;

// Video
// -----
#define VGA_WIDTH 320
#define VGA_HEIGHT 240
#define VGA_ROTATE -1  // 90 degrees anti-clockwise
#define VGA_SCALE_X vga_scale
#define VGA_SCALE_Y vga_scale
SimVideo video(VGA_WIDTH, VGA_HEIGHT, VGA_ROTATE);
float vga_scale = 2.5;

// Verilog module
// --------------
Vtop* top = NULL;

vluint64_t main_time = 0;	// Current simulation time.
double sc_time_stamp() {	// Called by $time in Verilog.
	return main_time;
}

int clk_sys_freq = 48000000;
SimClock clk_48(1); // 48mhz
SimClock clk_12(4); // 12mhz

// VCD trace logging
// -----------------
VerilatedVcdC* tfp = new VerilatedVcdC; //Trace
bool Trace = 0;
char Trace_Deep[3] = "99";
char Trace_File[30] = "sim.vcd";
char Trace_Deep_tmp[3] = "99";
char Trace_File_tmp[30] = "sim.vcd";
int  iTrace_Deep_tmp = 99;
char SaveModel_File_tmp[20] = "test", SaveModel_File[20] = "test";

//Trace Save/Restore
void save_model(const char* filenamep) {
	VerilatedSave os;
	os.open(filenamep);
	os << main_time; // user code must save the timestamp, etc
	os << *top;
}
void restore_model(const char* filenamep) {
	VerilatedRestore os;
	os.open(filenamep);
	os >> main_time;
	os >> *top;
}

// Audio
// -----
#define DISABLE_AUDIO
#ifndef DISABLE_AUDIO
SimAudio audio(clk_sys_freq, true);
#endif

// Reset simulation variables and clocks
void resetSim() {
	main_time = 0;
	top->reset = 1;
	clk_48.Reset();
	clk_12.Reset();
}

int verilate() {

	if (!Verilated::gotFinish()) {

		// Assert reset during startup
		if (main_time < initialReset) { top->reset = 1; }
		// Deassert reset after startup
		if (main_time == initialReset) { top->reset = 0; }

		// Clock dividers
		clk_48.Tick();
		clk_12.Tick();

		// Set clocks in core
		top->clk_48 = clk_48.clk;
		top->clk_12 = clk_12.clk;

		// Simulate both edges of fastest clock
		if (clk_48.clk != clk_48.old) {

			// System clock simulates HPS functions
			if (clk_12.clk) {
				input.BeforeEval();
				bus.BeforeEval();
			}
			top->eval();
			if (Trace) {
				if (!tfp->isOpen()) tfp->open(Trace_File);
				tfp->dump(main_time); //Trace
			}

			// System clock simulates HPS functions
			if (clk_12.clk) { bus.AfterEval(); }
		}

#ifndef DISABLE_AUDIO
		if (clk_48.IsRising())
		{
			audio.Clock(top->AUDIO_L, top->AUDIO_R);
		}
#endif

		// Output pixels on rising edge of pixel clock
		if (clk_48.IsRising() && top->top__DOT__ce_pix) {
			uint32_t colour = 0xFF000000 | top->VGA_B << 16 | top->VGA_G << 8 | top->VGA_R;
			video.Clock(top->VGA_HB, top->VGA_VB, top->VGA_HS, top->VGA_VS, colour);
		}

		if (clk_48.IsRising()) {
			main_time++;
		}
		return 1;
	}

	// Stop verilating and cleanup
	top->final();
	delete top;
	exit(0);
	return 0;
}

int main(int argc, char** argv, char** env) {

	// Create core and initialise
	top = new Vtop();
	Verilated::commandArgs(argc, argv);

	//Prepare for Dump Signals
	Verilated::traceEverOn(true); //Trace
	top->trace(tfp, 1);// atoi(Trace_Deep) );  // Trace 99 levels of hierarchy
	if (Trace) tfp->open(Trace_File);//"simx.vcd"); //Trace

#ifdef WIN32
	// Attach debug console to the verilated code
	Verilated::setDebug(console);
#endif

	// Attach bus
	bus.ioctl_addr = &top->ioctl_addr;
	bus.ioctl_index = &top->ioctl_index;
	bus.ioctl_wait = &top->ioctl_wait;
	bus.ioctl_download = &top->ioctl_download;
	bus.ioctl_upload = &top->ioctl_upload;
	bus.ioctl_wr = &top->ioctl_wr;
	bus.ioctl_dout = &top->ioctl_dout;
	bus.ioctl_din = &top->ioctl_din;

#ifndef DISABLE_AUDIO
	audio.Initialise();
#endif

	// Set up input module
	input.Initialise();
#ifdef WIN32
	input.SetMapping(input_up, DIK_UP);
	input.SetMapping(input_right, DIK_RIGHT);
	input.SetMapping(input_down, DIK_DOWN);
	input.SetMapping(input_left, DIK_LEFT);
	input.SetMapping(input_fire1, DIK_SPACE);
	input.SetMapping(input_start_1, DIK_1);
	input.SetMapping(input_start_2, DIK_2);
	input.SetMapping(input_coin_1, DIK_5);
	input.SetMapping(input_coin_2, DIK_6);
	input.SetMapping(input_coin_3, DIK_7);
	input.SetMapping(input_pause, DIK_P);
#else
	input.SetMapping(input_up, SDL_SCANCODE_UP);
	input.SetMapping(input_right, SDL_SCANCODE_RIGHT);
	input.SetMapping(input_down, SDL_SCANCODE_DOWN);
	input.SetMapping(input_left, SDL_SCANCODE_LEFT);
	input.SetMapping(input_fire1, SDL_SCANCODE_SPACE);
	input.SetMapping(input_start_1, SDL_SCANCODE_1);
	input.SetMapping(input_start_2, SDL_SCANCODE_2);
	input.SetMapping(input_coin_1, SDL_SCANCODE_3);
	input.SetMapping(input_coin_2, SDL_SCANCODE_4);
	input.SetMapping(input_coin_3, SDL_SCANCODE_5);
	input.SetMapping(input_pause, SDL_SCANCODE_P);
#endif
	// Setup video output
	if (video.Initialise(windowTitle) == 1) { return 1; }

	bus.QueueDownload("./test.bin", 0, true);


#ifdef WIN32
	MSG msg;
	ZeroMemory(&msg, sizeof(msg));
	while (msg.message != WM_QUIT)
	{
		if (PeekMessage(&msg, NULL, 0U, 0U, PM_REMOVE))
		{
			TranslateMessage(&msg);
			DispatchMessage(&msg);
			continue;
		}
#else
	bool done = false;
	while (!done)
	{
		SDL_Event event;
		while (SDL_PollEvent(&event))
		{
			ImGui_ImplSDL2_ProcessEvent(&event);
			if (event.type == SDL_QUIT)
				done = true;
		}
#endif
		video.StartFrame();

		input.Read();


		// Draw GUI
		// --------
		ImGui::NewFrame();

		// Simulation control window
		ImGui::Begin(windowTitle_Control);
		ImGui::SetWindowPos(windowTitle_Control, ImVec2(0, 0), ImGuiCond_Once);
		ImGui::SetWindowSize(windowTitle_Control, ImVec2(500, 150), ImGuiCond_Once);
		if (ImGui::Button("Reset simulation")) { resetSim(); } ImGui::SameLine();
		if (ImGui::Button("Start running")) { run_enable = 1; } ImGui::SameLine();
		if (ImGui::Button("Stop running")) { run_enable = 0; } ImGui::SameLine();
		ImGui::Checkbox("RUN", &run_enable);
		//ImGui::PopItemWidth();
		ImGui::SliderInt("Run batch size", &batchSize, 1, 250000);
		if (single_step == 1) { single_step = 0; }
		if (ImGui::Button("Single Step")) { run_enable = 0; single_step = 1; }
		ImGui::SameLine();
		if (multi_step == 1) { multi_step = 0; }
		if (ImGui::Button("Multi Step")) { run_enable = 0; multi_step = 1; }
		//ImGui::SameLine();
		ImGui::SliderInt("Multi step amount", &multi_step_amount, 8, 1024);

		ImGui::End();

		// Debug log window
		console.Draw(windowTitle_DebugLog, &showDebugLog, ImVec2(500, 700));
		ImGui::SetWindowPos(windowTitle_DebugLog, ImVec2(0, 160), ImGuiCond_Once);

		// Memory debug
		//ImGui::Begin("PGROM Editor");
		//mem_edit.DrawContents(top->top__DOT__uut__DOT__rom__DOT__mem, 32768, 0);
		//ImGui::End();

		// Trace/VCD window
		ImGui::Begin(windowTitle_Trace);
		ImGui::SetWindowPos(windowTitle_Trace, ImVec2(0, 870), ImGuiCond_Once);
		ImGui::SetWindowSize(windowTitle_Trace, ImVec2(500, 150), ImGuiCond_Once);

		if (ImGui::Button("Start VCD Export")) { Trace = 1; } ImGui::SameLine();
		if (ImGui::Button("Stop VCD Export")) { Trace = 0; } ImGui::SameLine();
		if (ImGui::Button("Flush VCD Export")) { tfp->flush(); } ImGui::SameLine();
		ImGui::Checkbox("Export VCD", &Trace);

		ImGui::PushItemWidth(120);
		if (ImGui::InputInt("Deep Level", &iTrace_Deep_tmp, 1, 100, ImGuiInputTextFlags_EnterReturnsTrue))
		{
			top->trace(tfp, iTrace_Deep_tmp);
		}

		if (ImGui::InputText("TraceFilename", Trace_File_tmp, IM_ARRAYSIZE(Trace_File), ImGuiInputTextFlags_EnterReturnsTrue))
		{
			strcpy(Trace_File, Trace_File_tmp); //TODO onChange Close and open new trace file
			tfp->close();
			if (Trace) tfp->open(Trace_File);
		};
		ImGui::Separator();
		if (ImGui::Button("Save Model")) { save_model(SaveModel_File); } ImGui::SameLine();
		if (ImGui::Button("Load Model")) {
			restore_model(SaveModel_File);
		} ImGui::SameLine();
		if (ImGui::InputText("SaveFilename", SaveModel_File_tmp, IM_ARRAYSIZE(SaveModel_File), ImGuiInputTextFlags_EnterReturnsTrue))
		{
			strcpy(SaveModel_File, SaveModel_File_tmp); //TODO onChange Close and open new trace file
		}
		ImGui::End();
		int windowX = 550;
		int windowWidth = (VGA_WIDTH * VGA_SCALE_X) + 24;
		int windowHeight = (VGA_HEIGHT * VGA_SCALE_Y) + 90;

		// Video window
		ImGui::Begin(windowTitle_Video);
		ImGui::SetWindowPos(windowTitle_Video, ImVec2(windowX, 0), ImGuiCond_Once);
		ImGui::SetWindowSize(windowTitle_Video, ImVec2(windowWidth, windowHeight), ImGuiCond_Once);

		ImGui::SetNextItemWidth(400);
		ImGui::SliderFloat("Zoom", &vga_scale, 1, 8); ImGui::SameLine();
		ImGui::SetNextItemWidth(200);
		ImGui::SliderInt("Rotate", &video.output_rotate, -1, 1); ImGui::SameLine();
		ImGui::Checkbox("Flip V", &video.output_vflip);
		ImGui::Text("main_time: %d frame_count: %d sim FPS: %f", main_time, video.count_frame, video.stats_fps);
		//ImGui::Text("pixel: %06d line: %03d", video.count_pixel, video.count_line);

		// Draw VGA output
		ImGui::Image(video.texture_id, ImVec2(video.output_width * VGA_SCALE_X, video.output_height * VGA_SCALE_Y));
		ImGui::End();


#ifndef DISABLE_AUDIO

		ImGui::Begin(windowTitle_Audio);
		ImGui::SetWindowPos(windowTitle_Audio, ImVec2(windowX, windowHeight), ImGuiCond_Once);
		ImGui::SetWindowSize(windowTitle_Audio, ImVec2(windowWidth, 250), ImGuiCond_Once);


		//float vol_l = ((signed short)(top->AUDIO_L) / 256.0f) / 256.0f;
		//float vol_r = ((signed short)(top->AUDIO_R) / 256.0f) / 256.0f;
		//ImGui::ProgressBar(vol_l + 0.5f, ImVec2(200, 16), 0); ImGui::SameLine();
		//ImGui::ProgressBar(vol_r + 0.5f, ImVec2(200, 16), 0);

		int ticksPerSec = (24000000 / 60);
		if (run_enable) {
			audio.CollectDebug((signed short)top->AUDIO_L, (signed short)top->AUDIO_R);
		}
		int channelWidth = (windowWidth / 2) - 16;
		ImPlot::CreateContext();
		if (ImPlot::BeginPlot("Audio - L", ImVec2(channelWidth, 220), ImPlotFlags_NoLegend | ImPlotFlags_NoMenus | ImPlotFlags_NoTitle)) {
			ImPlot::SetupAxes("T", "A", ImPlotAxisFlags_NoLabel | ImPlotAxisFlags_NoTickMarks, ImPlotAxisFlags_AutoFit | ImPlotAxisFlags_NoLabel | ImPlotAxisFlags_NoTickMarks);
			ImPlot::SetupAxesLimits(0, 1, -1, 1, ImPlotCond_Once);
			ImPlot::PlotStairs("", audio.debug_positions, audio.debug_wave_l, audio.debug_max_samples, audio.debug_pos);
			ImPlot::EndPlot();
		}
		ImGui::SameLine();
		if (ImPlot::BeginPlot("Audio - R", ImVec2(channelWidth, 220), ImPlotFlags_NoLegend | ImPlotFlags_NoMenus | ImPlotFlags_NoTitle)) {
			ImPlot::SetupAxes("T", "A", ImPlotAxisFlags_NoLabel | ImPlotAxisFlags_NoTickMarks, ImPlotAxisFlags_AutoFit | ImPlotAxisFlags_NoLabel | ImPlotAxisFlags_NoTickMarks);
			ImPlot::SetupAxesLimits(0, 1, -1, 1, ImPlotCond_Once);
			ImPlot::PlotStairs("", audio.debug_positions, audio.debug_wave_r, audio.debug_max_samples, audio.debug_pos);
			ImPlot::EndPlot();
		}
		ImPlot::DestroyContext();
		ImGui::End();
#endif

		video.UpdateTexture();


		// Pass inputs to sim
		top->inputs = 0;
		for (int i = 0; i < input.inputCount; i++)
		{
			if (input.inputs[i]) { top->inputs |= (1 << i); }
		}

		// Run simulation
		if (run_enable) {
			for (int step = 0; step < batchSize; step++) { verilate(); }
		}
		else {
			if (single_step) { verilate(); }
			if (multi_step) {
				for (int step = 0; step < multi_step_amount; step++) { verilate(); }
			}
		}
	}

	// Clean up before exit
	// --------------------

#ifndef DISABLE_AUDIO
	audio.CleanUp();
#endif 
	video.CleanUp();
	input.CleanUp();

	return 0;
}
