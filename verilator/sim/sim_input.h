#pragma once
#ifndef _MSC_VER
#else
#define WIN32
#pragma comment(lib, "dinput8.lib")
#pragma comment(lib, "dxguid.lib")
#endif
#include "verilated_heavy.h"
#include <queue>
#include <vector>

struct SimInput_PS2KeyEvent
{
public:
	char code;
	bool pressed;
	bool extended;

	SimInput_PS2KeyEvent(char code, bool pressed, bool extended)
	{
		this->code = code;
		this->pressed = pressed;
		this->extended = extended;
	}
};

struct SimInput
{
public:
	int inputCount = 0;
	bool inputs[16] = { false };
	int mappings[16] = { 0 };

	IData* ps2_key = NULL;
	std::queue<SimInput_PS2KeyEvent> keyEvents;
	unsigned int keyEventTimer = 0;
	unsigned int keyEventWait = 0;

	void Read();
	int Initialise();
	void CleanUp();
	void SetMapping(int index, int code);
	void BeforeEval(void);
	SimInput(int count);
	~SimInput();
};
