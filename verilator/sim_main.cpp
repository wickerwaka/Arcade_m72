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


// Simulation control
// ------------------
int initialReset = 48;
bool run_enable = 0;
int batchSize = 150000;
bool single_step = 0;
bool multi_step = 0;
bool cpu_single_step = 0;
bool cpu_until_write = 0;
bool cpu_until_io = 0;
bool cpu_until_invalid_read = 0;
int multi_step_amount = 1024;
int force_sprite_obj = 0;

enum BreakCondition : unsigned int
{
	BREAK_NEXT_PC = 1 << 0,
	BREAK_WRITE = 1 << 1,
	BREAK_IO = 1 << 2,
	BREAK_PC = 1 << 3,
	BREAK_DATA_ADDR = 1 << 4,
	BREAK_SCANLINE = 1 << 6,
	BREAK_INT_REQ = 1 << 7,
	BREAK_INT_TOGGLE = 1 << 8,
};

struct Breaker {
	int condition = 0;
	int pc = 0;
	int addr = 0;
	int scanline = 0;

	bool check() {
		if (!condition) return false;

		const bool stb = top->top__DOT__m72__DOT__stb != 0;
		const bool we = top->top__DOT__m72__DOT__cpu_we != 0;
		const bool io = top->top__DOT__m72__DOT__cpu_iorq != 0;
		const unsigned int cpu_addr = top->top__DOT__m72__DOT__cpu_addr << 1;
		const unsigned int opcode = top->top__DOT__m72__DOT__zet_inst__DOT__core__DOT__opcode;
		const bool exec = top->top__DOT__m72__DOT__zet_inst__DOT__core__DOT__exec_st != 0;


		if ((condition & BREAK_WRITE) && (!we || !stb)) return false;
		if ((condition & BREAK_IO) && (!io || !stb)) return false;

		if ((condition & BREAK_DATA_ADDR) && (!stb || (cpu_addr != addr))) return false;

		//if ((condition & BREAK_INT_REQ) && (!top->top__DOT__m72__DOT__pic__DOT__intr)) return false;
		if ((condition & BREAK_INT_TOGGLE) && (exec == false || (opcode != 0xfb && opcode != 0xfa))) return false;

		return true;
	}
};

Breaker breaker;
Breaker active_breaker;

struct Obj {
	uint16_t y : 9;
	uint16_t pad0 : 7;
	
	uint16_t code : 16;
	
	uint16_t color : 4;
	uint16_t pad1 : 6;
	uint16_t flipy : 1;
	uint16_t flipx : 1;
	uint16_t height : 2;
	uint16_t width : 2;

	uint16_t x : 10;
	uint16_t pad2 : 6;
};

const Obj* sprite_data = (Obj*)top->top__DOT__m72__DOT__sprite__DOT__objram__DOT__ram.m_array.data();
// Debug GUI 
// ---------
const char* windowTitle = "Verilator Sim: Arcade-M72";
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
#define VGA_WIDTH 384
#define VGA_HEIGHT 256
#define VGA_ROTATE 0  // 90 degrees anti-clockwise
#define VGA_SCALE_X vga_scale
#define VGA_SCALE_Y vga_scale
SimVideo video(VGA_WIDTH, VGA_HEIGHT, VGA_ROTATE);
float vga_scale = 2.5;


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

// Signal Macros
#define CPU3(a, b, c) top->top__DOT__m72__DOT__zet_inst__DOT__ ##a ##__DOT__ ##b ##__DOT__ ##c
#define CPU2(a, b) top->top__DOT__m72__DOT__zet_inst__DOT__ ##a ##__DOT__ ##b
#define CPU1(a) top->top__DOT__m72__DOT__zet_inst__DOT__ ##a

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

		top->force_code = force_sprite_obj;

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

		//if (clk_48.IsRising()) {
			main_time++;
		//}
		return 1;
	}

	// Stop verilating and cleanup
	top->final();
	delete top;
	exit(0);
	return 0;
}

void print_opcode() {
	switch (top->top__DOT__m72__DOT__zet_inst__DOT__core__DOT__opcode) {
	case 0x00: ImGui::Text("ADD		Eb	Gb"); break;
	case 0x01: ImGui::Text("ADD		Ev	Gv"); break;
	case 0x02: ImGui::Text("ADD		Gb	Eb"); break;
	case 0x03: ImGui::Text("ADD		Gv	Ev"); break;
	case 0x04: ImGui::Text("ADD		AL	Ib"); break;
	case 0x05: ImGui::Text("ADD		eAX	Iv"); break;
	case 0x06: ImGui::Text("PUSH	ES"); break;
	case 0x07: ImGui::Text("POP		ES"); break;
	case 0x08: ImGui::Text("OR		Eb	Gb"); break;
	case 0x09: ImGui::Text("OR		Ev	Gv"); break;
	case 0x0A: ImGui::Text("OR		Gb	Eb"); break;
	case 0x0B: ImGui::Text("OR		Gv	Ev"); break;
	case 0x0C: ImGui::Text("OR		AL	Ib"); break;
	case 0x0D: ImGui::Text("OR		eAX	Iv"); break;
	case 0x0E: ImGui::Text("PUSH	CS"); break;
	case 0x0F: ImGui::Text("--"); break;
	case 0x10: ImGui::Text("ADC		Eb	Gb"); break;
	case 0x11: ImGui::Text("ADC		Ev	Gv"); break;
	case 0x12: ImGui::Text("ADC		Gb	Eb"); break;
	case 0x13: ImGui::Text("ADC		Gv	Ev"); break;
	case 0x14: ImGui::Text("ADC		AL	Ib"); break;
	case 0x15: ImGui::Text("ADC		eAX	Iv"); break;
	case 0x16: ImGui::Text("PUSH	SS"); break;
	case 0x17: ImGui::Text("POP		SS"); break;
	case 0x18: ImGui::Text("SBB		Eb	Gb"); break;
	case 0x19: ImGui::Text("SBB		Ev	Gv"); break;
	case 0x1A: ImGui::Text("SBB		Gb	Eb"); break;
	case 0x1B: ImGui::Text("SBB		Gv	Ev"); break;
	case 0x1C: ImGui::Text("SBB		AL	Ib"); break;
	case 0x1D: ImGui::Text("SBB		eAX	Iv"); break;
	case 0x1E: ImGui::Text("PUSH	DS"); break;
	case 0x1F: ImGui::Text("POP		DS"); break;
	case 0x20: ImGui::Text("AND		Eb	Gb"); break;
	case 0x21: ImGui::Text("AND		Ev	Gv"); break;
	case 0x22: ImGui::Text("AND		Gb	Eb"); break;
	case 0x23: ImGui::Text("AND		Gv	Ev"); break;
	case 0x24: ImGui::Text("AND		AL	Ib"); break;
	case 0x25: ImGui::Text("AND		eAX	Iv"); break;
	case 0x26: ImGui::Text("ES:"); break;
	case 0x27: ImGui::Text("DAA"); break;
	case 0x28: ImGui::Text("SUB		Eb	Gb"); break;
	case 0x29: ImGui::Text("SUB		Ev	Gv"); break;
	case 0x2A: ImGui::Text("SUB		Gb	Eb"); break;
	case 0x2B: ImGui::Text("SUB		Gv	Ev"); break;
	case 0x2C: ImGui::Text("SUB		AL	Ib"); break;
	case 0x2D: ImGui::Text("SUB		eAX	Iv"); break;
	case 0x2E: ImGui::Text("CS:"); break;
	case 0x2F: ImGui::Text("DAS"); break;
	case 0x30: ImGui::Text("XOR		Eb	Gb"); break;
	case 0x31: ImGui::Text("XOR		Ev	Gv"); break;
	case 0x32: ImGui::Text("XOR		Gb	Eb"); break;
	case 0x33: ImGui::Text("XOR		Gv	Ev"); break;
	case 0x34: ImGui::Text("XOR		AL	Ib"); break;
	case 0x35: ImGui::Text("XOR		eAX	Iv"); break;
	case 0x36: ImGui::Text("SS:"); break;
	case 0x37: ImGui::Text("AAA"); break;
	case 0x38: ImGui::Text("CMP		Eb	Gb"); break;
	case 0x39: ImGui::Text("CMP		Ev	Gv"); break;
	case 0x3A: ImGui::Text("CMP		Gb	Eb"); break;
	case 0x3B: ImGui::Text("CMP		Gv	Ev"); break;
	case 0x3C: ImGui::Text("CMP		AL	Ib"); break;
	case 0x3D: ImGui::Text("CMP		eAX	Iv"); break;
	case 0x3E: ImGui::Text("DS:"); break;
	case 0x3F: ImGui::Text("AAS"); break;
	case 0x40: ImGui::Text("INC		eAX"); break;
	case 0x41: ImGui::Text("INC		eCX"); break;
	case 0x42: ImGui::Text("INC		eDX"); break;
	case 0x43: ImGui::Text("INC		eBX"); break;
	case 0x44: ImGui::Text("INC		eSP"); break;
	case 0x45: ImGui::Text("INC		eBP"); break;
	case 0x46: ImGui::Text("INC		eSI"); break;
	case 0x47: ImGui::Text("INC		eDI"); break;
	case 0x48: ImGui::Text("DEC		eAX"); break;
	case 0x49: ImGui::Text("DEC		eCX"); break;
	case 0x4A: ImGui::Text("DEC		eDX"); break;
	case 0x4B: ImGui::Text("DEC		eBX"); break;
	case 0x4C: ImGui::Text("DEC		eSP"); break;
	case 0x4D: ImGui::Text("DEC		eBP"); break;
	case 0x4E: ImGui::Text("DEC		eSI"); break;
	case 0x4F: ImGui::Text("DEC		eDI"); break;
	case 0x50: ImGui::Text("PUSH	eAX"); break;
	case 0x51: ImGui::Text("PUSH	eCX"); break;
	case 0x52: ImGui::Text("PUSH	eDX"); break;
	case 0x53: ImGui::Text("PUSH	eBX"); break;
	case 0x54: ImGui::Text("PUSH	eSP"); break;
	case 0x55: ImGui::Text("PUSH	eBP"); break;
	case 0x56: ImGui::Text("PUSH	eSI"); break;
	case 0x57: ImGui::Text("PUSH	eDI"); break;
	case 0x58: ImGui::Text("POP		eAX"); break;
	case 0x59: ImGui::Text("POP		eCX"); break;
	case 0x5A: ImGui::Text("POP		eDX"); break;
	case 0x5B: ImGui::Text("POP		eBX"); break;
	case 0x5C: ImGui::Text("POP		eSP"); break;
	case 0x5D: ImGui::Text("POP		eBP"); break;
	case 0x5E: ImGui::Text("POP		eSI"); break;
	case 0x5F: ImGui::Text("POP		eDI"); break;
	case 0x60: ImGui::Text("--"); break;
	case 0x61: ImGui::Text("--"); break;
	case 0x62: ImGui::Text("--"); break;
	case 0x63: ImGui::Text("--"); break;
	case 0x64: ImGui::Text("--"); break;
	case 0x65: ImGui::Text("--"); break;
	case 0x66: ImGui::Text("--"); break;
	case 0x67: ImGui::Text("--"); break;
	case 0x68: ImGui::Text("--"); break;
	case 0x69: ImGui::Text("--"); break;
	case 0x6A: ImGui::Text("--"); break;
	case 0x6B: ImGui::Text("--"); break;
	case 0x6C: ImGui::Text("--"); break;
	case 0x6D: ImGui::Text("--"); break;
	case 0x6E: ImGui::Text("--"); break;
	case 0x6F: ImGui::Text("--"); break;
	case 0x70: ImGui::Text("JO		Jb"); break;
	case 0x71: ImGui::Text("JNO		Jb"); break;
	case 0x72: ImGui::Text("JB		Jb"); break;
	case 0x73: ImGui::Text("JNB		Jb"); break;
	case 0x74: ImGui::Text("JZ		Jb"); break;
	case 0x75: ImGui::Text("JNZ		Jb"); break;
	case 0x76: ImGui::Text("JBE		Jb"); break;
	case 0x77: ImGui::Text("JA		Jb"); break;
	case 0x78: ImGui::Text("JS		Jb"); break;
	case 0x79: ImGui::Text("JNS		Jb"); break;
	case 0x7A: ImGui::Text("JPE		Jb"); break;
	case 0x7B: ImGui::Text("JPO		Jb"); break;
	case 0x7C: ImGui::Text("JL		Jb"); break;
	case 0x7D: ImGui::Text("JGE		Jb"); break;
	case 0x7E: ImGui::Text("JLE		Jb"); break;
	case 0x7F: ImGui::Text("JG		Jb"); break;
	case 0x80: ImGui::Text("GRP1	Eb	Ib"); break;
	case 0x81: ImGui::Text("GRP1	Ev	Iv"); break;
	case 0x82: ImGui::Text("GRP1	Eb	Ib"); break;
	case 0x83: ImGui::Text("GRP1	Ev	Ib"); break;
	case 0x84: ImGui::Text("TEST	Gb	Eb"); break;
	case 0x85: ImGui::Text("TEST	Gv	Ev"); break;
	case 0x86: ImGui::Text("XCHG	Gb	Eb"); break;
	case 0x87: ImGui::Text("XCHG	Gv	Ev"); break;
	case 0x88: ImGui::Text("MOV		Eb	Gb"); break;
	case 0x89: ImGui::Text("MOV		Ev	Gv"); break;
	case 0x8A: ImGui::Text("MOV		Gb	Eb"); break;
	case 0x8B: ImGui::Text("MOV		Gv	Ev"); break;
	case 0x8C: ImGui::Text("MOV		Ew	Sw"); break;
	case 0x8D: ImGui::Text("LEA		Gv	M"); break;
	case 0x8E: ImGui::Text("MOV		Sw	Ew"); break;
	case 0x8F: ImGui::Text("POP		Ev"); break;
	case 0x90: ImGui::Text("NOP"); break;
	case 0x91: ImGui::Text("XCHG	eCX eAX"); break;
	case 0x92: ImGui::Text("XCHG	eDX eAX"); break;
	case 0x93: ImGui::Text("XCHG	eBX eAX"); break;
	case 0x94: ImGui::Text("XCHG	eSP eAX"); break;
	case 0x95: ImGui::Text("XCHG	eBP eAX"); break;
	case 0x96: ImGui::Text("XCHG	eSI eAX"); break;
	case 0x97: ImGui::Text("XCHG	eDI eAX"); break;
	case 0x98: ImGui::Text("CBW"); break;
	case 0x99: ImGui::Text("CWD"); break;
	case 0x9A: ImGui::Text("CALL	Ap"); break;
	case 0x9B: ImGui::Text("WAIT"); break;
	case 0x9C: ImGui::Text("PUSHF"); break;
	case 0x9D: ImGui::Text("POPF"); break;
	case 0x9E: ImGui::Text("SAHF"); break;
	case 0x9F: ImGui::Text("LAHF"); break;
	case 0xA0: ImGui::Text("MOV		AL	Ob"); break;
	case 0xA1: ImGui::Text("MOV		eAX	Ov"); break;
	case 0xA2: ImGui::Text("MOV		Ob	AL"); break;
	case 0xA3: ImGui::Text("MOV		Ov	eAX"); break;
	case 0xA4: ImGui::Text("MOVSB"); break;
	case 0xA5: ImGui::Text("MOVSW"); break;
	case 0xA6: ImGui::Text("CMPSB"); break;
	case 0xA7: ImGui::Text("CMPSW"); break;
	case 0xA8: ImGui::Text("TEST	AL	Ib"); break;
	case 0xA9: ImGui::Text("TEST	eAX	Iv"); break;
	case 0xAA: ImGui::Text("STOSB"); break;
	case 0xAB: ImGui::Text("STOSW"); break;
	case 0xAC: ImGui::Text("LODSB"); break;
	case 0xAD: ImGui::Text("LODSW"); break;
	case 0xAE: ImGui::Text("SCASB"); break;
	case 0xAF: ImGui::Text("SCASW"); break;
	case 0xB0: ImGui::Text("MOV		AL	Ib"); break;
	case 0xB1: ImGui::Text("MOV		CL	Ib"); break;
	case 0xB2: ImGui::Text("MOV		DL	Ib"); break;
	case 0xB3: ImGui::Text("MOV		BL	Ib"); break;
	case 0xB4: ImGui::Text("MOV		AH	Ib"); break;
	case 0xB5: ImGui::Text("MOV		CH	Ib"); break;
	case 0xB6: ImGui::Text("MOV		DH	Ib"); break;
	case 0xB7: ImGui::Text("MOV		BH	Ib"); break;
	case 0xB8: ImGui::Text("MOV		eAX	Iv"); break;
	case 0xB9: ImGui::Text("MOV		eCX	Iv"); break;
	case 0xBA: ImGui::Text("MOV		eDX	Iv"); break;
	case 0xBB: ImGui::Text("MOV		eBX	Iv"); break;
	case 0xBC: ImGui::Text("MOV		eSP	Iv"); break;
	case 0xBD: ImGui::Text("MOV		eBP	Iv"); break;
	case 0xBE: ImGui::Text("MOV		eSI	Iv"); break;
	case 0xBF: ImGui::Text("MOV		eDI	Iv"); break;
	case 0xC0: ImGui::Text("--"); break;
	case 0xC1: ImGui::Text("--"); break;
	case 0xC2: ImGui::Text("RET		Iw"); break;
	case 0xC3: ImGui::Text("RET"); break;
	case 0xC4: ImGui::Text("LES		Gv	Mp"); break;
	case 0xC5: ImGui::Text("LDS		Gv	Mp"); break;
	case 0xC6: ImGui::Text("MOV		Eb	Ib"); break;
	case 0xC7: ImGui::Text("MOV		Ev	Iv"); break;
	case 0xC8: ImGui::Text("--"); break;
	case 0xC9: ImGui::Text("--"); break;
	case 0xCA: ImGui::Text("RETF	Iw"); break;
	case 0xCB: ImGui::Text("RETF"); break;
	case 0xCC: ImGui::Text("INT		3"); break;
	case 0xCD: ImGui::Text("INT		Ib"); break;
	case 0xCE: ImGui::Text("INTO"); break;
	case 0xCF: ImGui::Text("IRET"); break;
	case 0xD0: ImGui::Text("GRP2	Eb	1"); break;
	case 0xD1: ImGui::Text("GRP2	Ev	1"); break;
	case 0xD2: ImGui::Text("GRP2	Eb	CL"); break;
	case 0xD3: ImGui::Text("GRP2	Ev	CL"); break;
	case 0xD4: ImGui::Text("AAM		I0"); break;
	case 0xD5: ImGui::Text("AAD		I0"); break;
	case 0xD6: ImGui::Text("--"); break;
	case 0xD7: ImGui::Text("XLAT"); break;
	case 0xD8: ImGui::Text("--"); break;
	case 0xD9: ImGui::Text("--"); break;
	case 0xDA: ImGui::Text("--"); break;
	case 0xDB: ImGui::Text("--"); break;
	case 0xDC: ImGui::Text("--"); break;
	case 0xDD: ImGui::Text("--"); break;
	case 0xDE: ImGui::Text("--"); break;
	case 0xDF: ImGui::Text("--"); break;
	case 0xE0: ImGui::Text("LOOPNZ	Jb"); break;
	case 0xE1: ImGui::Text("LOOPZ	Jb"); break;
	case 0xE2: ImGui::Text("LOOP	Jb"); break;
	case 0xE3: ImGui::Text("JCXZ	Jb"); break;
	case 0xE4: ImGui::Text("IN		AL	Ib"); break;
	case 0xE5: ImGui::Text("IN		eAX	Ib"); break;
	case 0xE6: ImGui::Text("OUT		Ib	AL"); break;
	case 0xE7: ImGui::Text("OUT		Ib	eAX"); break;
	case 0xE8: ImGui::Text("CALL	Jv"); break;
	case 0xE9: ImGui::Text("JMP		Jv"); break;
	case 0xEA: ImGui::Text("JMP		Ap"); break;
	case 0xEB: ImGui::Text("JMP		Jb"); break;
	case 0xEC: ImGui::Text("IN		AL	DX"); break;
	case 0xED: ImGui::Text("IN		eAX	DX"); break;
	case 0xEE: ImGui::Text("OUT		DX	AL"); break;
	case 0xEF: ImGui::Text("OUT		DX	eAX"); break;
	case 0xF0: ImGui::Text("LOCK"); break;
	case 0xF1: ImGui::Text("--"); break;
	case 0xF2: ImGui::Text("REPNZ"); break;
	case 0xF3: ImGui::Text("REPZ"); break;
	case 0xF4: ImGui::Text("HLT"); break;
	case 0xF5: ImGui::Text("CMC"); break;
	case 0xF6: ImGui::Text("GRP3a	Eb"); break;
	case 0xF7: ImGui::Text("GRP3b	Ev"); break;
	case 0xF8: ImGui::Text("CLC"); break;
	case 0xF9: ImGui::Text("STC"); break;
	case 0xFA: ImGui::Text("CLI"); break;
	case 0xFB: ImGui::Text("STI"); break;
	case 0xFC: ImGui::Text("CLD"); break;
	case 0xFD: ImGui::Text("STD"); break;
	case 0xFE: ImGui::Text("GRP4	Eb"); break;
	case 0xFF: ImGui::Text("GRP5	Ev"); break;
	}
}

struct SplitMemory {
	uint8_t* high;
	uint8_t* low;
};

ImU8 SplitMemoryRead(const ImU8* data, size_t off)
{
	const SplitMemory* mem = (const SplitMemory*)data;
	if (off & 1) return mem->high[off >> 1];
	return mem->low[off >> 1];
}

void SplitMemoryWrite(ImU8* data, size_t off, ImU8 d)
{
	SplitMemory* mem = (SplitMemory*)data;
	if (off & 1) mem->high[off >> 1] = d;
	else mem->low[off >> 1] = d;
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

	bus.QueueDownload("../roms/rt_r-h0-b.1b", 0, true);
	bus.QueueDownload("../roms/rt_r-l0-b.3b", 0);
	bus.QueueDownload("../roms/rt_r-h1-b.1c", 0);
	bus.QueueDownload("../roms/rt_r-l1-b.3c", 0);
	bus.QueueDownload("../roms/rt_b-a0.3c", 0);
	bus.QueueDownload("../roms/rt_b-a1.3d", 0);
	bus.QueueDownload("../roms/rt_b-a2.3a", 0);
	bus.QueueDownload("../roms/rt_b-a3.3e", 0);
	bus.QueueDownload("../roms/rt_b-b0.3j", 0);
	bus.QueueDownload("../roms/rt_b-b1.3k", 0);
	bus.QueueDownload("../roms/rt_b-b2.3h", 0);
	bus.QueueDownload("../roms/rt_b-b3.3f", 0);
	bus.QueueDownload("../roms/rt_r-00.1h", 0);
	bus.QueueDownload("../roms/rt_r-01.1j", 0);
	bus.QueueDownload("../roms/rt_r-10.1k", 0);
	bus.QueueDownload("../roms/rt_r-11.1l", 0);
	bus.QueueDownload("../roms/rt_r-20.3h", 0);
	bus.QueueDownload("../roms/rt_r-21.3j", 0);
	bus.QueueDownload("../roms/rt_r-30.3k", 0);
	bus.QueueDownload("../roms/rt_r-31.3l", 0);

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
		ImGui::SetWindowSize(windowTitle_Control, ImVec2(500, 250), ImGuiCond_Once);
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

		ImGui::Text("Break at:");
		ImGui::Separator();

		ImGui::CheckboxFlags("Next PC", &breaker.condition, BREAK_NEXT_PC);
		ImGui::SameLine();
		ImGui::CheckboxFlags("Write Op", &breaker.condition, BREAK_WRITE);
		ImGui::SameLine();
		ImGui::CheckboxFlags("IO Op", &breaker.condition, BREAK_IO);
		ImGui::CheckboxFlags("IRQ", &breaker.condition, BREAK_INT_REQ);
		ImGui::SameLine();
		ImGui::CheckboxFlags("IRQ Toggle", &breaker.condition, BREAK_INT_TOGGLE);


		ImGui::CheckboxFlags("PC", &breaker.condition, BREAK_PC);
		ImGui::SameLine();
		ImGui::SetNextItemWidth(50);
		static char pc_hex[64] = "";
		if (ImGui::InputText("Address##pc", pc_hex, IM_ARRAYSIZE(pc_hex), ImGuiInputTextFlags_CharsHexadecimal)) {
			breaker.pc = strtol(pc_hex, nullptr, 16);
		}

		ImGui::CheckboxFlags("Data", &breaker.condition, BREAK_DATA_ADDR);
		ImGui::SameLine();
		static char addr_hex[64] = "";
		ImGui::SetNextItemWidth(50);
		if (ImGui::InputText("Address##data", addr_hex, IM_ARRAYSIZE(addr_hex), ImGuiInputTextFlags_CharsHexadecimal)) {
			breaker.addr = strtol(addr_hex, nullptr, 16);
		}

		ImGui::CheckboxFlags("Scanline", &breaker.condition, BREAK_SCANLINE);
		ImGui::SameLine();
		ImGui::SetNextItemWidth(80);
		ImGui::InputInt("##scanline", &breaker.scanline);

		/*
		if (cpu_single_step == 1) { cpu_single_step = 0; }
		if (ImGui::Button("CPU Single Step")) { run_enable = 0; cpu_single_step = 1; }
		if (cpu_until_io == 1) { cpu_until_io = 0; }
		if (ImGui::Button("CPU Run to IO")) { run_enable = 0; cpu_until_io = 1; }
		if (cpu_until_write == 1) { cpu_until_write = 0; }
		if (ImGui::Button("CPU Run to Write")) { run_enable = 0; cpu_until_write = 1; }
		if (cpu_until_invalid_read == 1) { cpu_until_invalid_read = 0; }
		if (ImGui::Button("CPU Run to Invalid Read")) { run_enable = 0; cpu_until_invalid_read = 1; }
		*/

		ImGui::End();

		// Debug log window
		console.Draw(windowTitle_DebugLog, &showDebugLog, ImVec2(500, 700));
		ImGui::SetWindowPos(windowTitle_DebugLog, ImVec2(0, 160), ImGuiCond_Once);

		ImGui::Begin("Zet 8086 Core Registers");
		//ImGui::Text("addr_fetch: 0x%05X", top->sim_m72__DOT__cpu_inst__DOT__addr_fetch);
		ImGui::Text("  opcode: 0x%02X", top->top__DOT__m72__DOT__zet_inst__DOT__core__DOT__opcode); ImGui::SameLine(); print_opcode();
		ImGui::Text("      pc: 0x%06X", top->top__DOT__m72__DOT__zet_inst__DOT__core__DOT__pc);
		ImGui::Text("cpu_addr: 0x%06X", top->top__DOT__m72__DOT__cpu_addr << 1);
		ImGui::Text(" cpu_din: 0x%04X", top->top__DOT__m72__DOT__cpu_din);
		ImGui::Text("cpu_dout: 0x%04X", top->top__DOT__m72__DOT__cpu_dout);
		ImGui::Text("     sel: %d%d", top->top__DOT__m72__DOT__cpu_sel >> 1, top->top__DOT__m72__DOT__cpu_sel & 1);
		ImGui::Text("     stb: %d", top->top__DOT__m72__DOT__stb);
		ImGui::Text("      io: %d", top->top__DOT__m72__DOT__cpu_iorq);
		ImGui::Text("      we: %d", top->top__DOT__m72__DOT__cpu_we);

		ImGui::Text("      sw: %d", top->top__DOT__m72__DOT__SW);
		ImGui::Text("    flag: %d", top->top__DOT__m72__DOT__FLAG);
		ImGui::Text("     dsw: %d", top->top__DOT__m72__DOT__DSW);
		ImGui::Text("     snd: %d", top->top__DOT__m72__DOT__SND);
		ImGui::Text("    fset: %d", top->top__DOT__m72__DOT__FSET);
		ImGui::Text("  dma_on: %d", top->top__DOT__m72__DOT__DMA_ON);
		ImGui::Text("    iset: %d", top->top__DOT__m72__DOT__ISET);
		ImGui::Text("   intcs: %d", top->top__DOT__m72__DOT__INTCS);

		ImGui::End();

		ImGui::Begin("Video Parameters");
		ImGui::Text("H: %3d (%3d)", top->top__DOT__m72__DOT__kna70h015__DOT__H, top->top__DOT__m72__DOT__kna70h015__DOT__HE);
		ImGui::Text("V: %3d (%3d)", top->top__DOT__m72__DOT__kna70h015__DOT__V, top->top__DOT__m72__DOT__kna70h015__DOT__VE);
		ImGui::Text("Int Line: %d", top->top__DOT__m72__DOT__kna70h015__DOT__h_int_line);
		ImGui::Text("HINT: %d VBLK: %d", top->top__DOT__m72__DOT__kna70h015__DOT__HINT, top->top__DOT__m72__DOT__kna70h015__DOT__VBLK);
		ImGui::Text("AX: %3d AY: %3d", top->top__DOT__m72__DOT__board_b_d__DOT__layer_a__DOT__adj_h, top->top__DOT__m72__DOT__board_b_d__DOT__layer_a__DOT__adj_v);
		ImGui::Text("BX: %3d BY: %3d", top->top__DOT__m72__DOT__board_b_d__DOT__layer_b__DOT__adj_h, top->top__DOT__m72__DOT__board_b_d__DOT__layer_b__DOT__adj_v);
		ImGui::InputInt("Force Sprite", &force_sprite_obj);
		ImGui::End();

		// Memory debug
		SplitMemory smem;
		smem.high = top->top__DOT__m72__DOT__ram_h__DOT__ram.m_array.data();
		smem.low = top->top__DOT__m72__DOT__ram_l__DOT__ram.m_array.data();
		mem_edit.ReadFn = SplitMemoryRead;
		mem_edit.WriteFn = SplitMemoryWrite;
		ImGui::Begin("Work RAM");
		mem_edit.DrawContents(&smem, 16 * 1024, 0);
		ImGui::End();

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
			bool prev_cond = breaker.check();
			for (int step = 0; step < batchSize; step++) {
				if (breaker.check()) {
					if (!prev_cond) {
						run_enable = 0;
						break;
					}
				} else {
					prev_cond = false;
				}

				verilate();
			}
		}
		else {
			if (single_step) { verilate(); }
			if (multi_step) {
				bool prev_cond = breaker.check();
				for (int step = 0; step < multi_step_amount; step++) { 
					if (breaker.check()) {
						if (!prev_cond) {
							break;
						}
					}
					else {
						prev_cond = false;
					}
					verilate();
				}
			}
			if (cpu_single_step) {
				int start_pc = top->top__DOT__m72__DOT__zet_inst__DOT__core__DOT__fetch__DOT__pc;
				while (top->top__DOT__m72__DOT__zet_inst__DOT__core__DOT__fetch__DOT__pc == start_pc) {
					verilate();
				}
			}
			if (cpu_until_write) {
				while (top->top__DOT__m72__DOT__cpu_we == 0) {
					verilate();
				}
			}
			if (cpu_until_io) {
				while (top->top__DOT__m72__DOT__cpu_iorq && top->top__DOT__m72__DOT__stb) {
					verilate();
				}
				while (!top->top__DOT__m72__DOT__cpu_iorq || !top->top__DOT__m72__DOT__stb) {
					verilate();
				}
			}
			if (cpu_until_invalid_read) {
				unsigned char prev = top->top__DOT__m72__DOT__board_b_d__DOT__kna91h014__DOT__ram_a[2];
				printf("Starting value: %d\n", prev);
				while (top->top__DOT__m72__DOT__board_b_d__DOT__kna91h014__DOT__ram_a[2] == prev) {
					verilate();
				}
				printf("Ending value: %d\n", top->top__DOT__m72__DOT__board_b_d__DOT__kna91h014__DOT__ram_a[2]);
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
