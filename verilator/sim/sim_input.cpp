#pragma once

#include "sim_input.h"

#include <string>

#ifndef _MSC_VER

#else
#define WIN32
#include <dinput.h>
//#define DIRECTINPUT_VERSION 0x0800
IDirectInput8* m_directInput;
IDirectInputDevice8* m_keyboard;
unsigned char m_keyboardState[256];
#endif
#include <vector>

// - Core inputs
//#define VSW1    top->top__DOT__sw1
//#define VSW2    top->top__DOT__sw2
//#define PLAYERINPUT top->top__DOT__playerinput
//#define JS      top->top__DOT__joystick
//void js_assert(int s) { JS &= ~(1 << s); }
//void js_deassert(int s) { JS |= 1 << s; }
//void playinput_assert(int s) { PLAYERINPUT &= ~(1 << s); }
//void playinput_deassert(int s) { PLAYERINPUT |= (1 << s); }

int inputCount = 0;
bool inputs[16];
int mappings[16];

bool ReadKeyboard()
{
	HRESULT result;

	// Read the keyboard device.
	result = m_keyboard->GetDeviceState(sizeof(m_keyboardState), (LPVOID)&m_keyboardState);
	if (FAILED(result))
	{
		// If the keyboard lost focus or was not acquired then try to get control back.
		if ((result == DIERR_INPUTLOST) || (result == DIERR_NOTACQUIRED)) { m_keyboard->Acquire(); }
		else { return false; }
	}
	return true;
}

int SimInput::Initialise() {

	m_directInput = 0;
	m_keyboard = 0;
	HRESULT result;
	// Initialize the main direct input interface.
	result = DirectInput8Create(GetModuleHandle(nullptr), DIRECTINPUT_VERSION, IID_IDirectInput8, (void**)&m_directInput, NULL);
	if (FAILED(result)) { return false; }
	// Initialize the direct input interface for the keyboard.
	result = m_directInput->CreateDevice(GUID_SysKeyboard, &m_keyboard, NULL);
	if (FAILED(result)) { return false; }
	// Set the data format.  In this case since it is a keyboard we can use the predefined data format.
	result = m_keyboard->SetDataFormat(&c_dfDIKeyboard);
	if (FAILED(result)) { return false; }
	// Now acquire the keyboard.
	result = m_keyboard->Acquire();
	if (FAILED(result)) { return false; }

	return 0;
}

void SimInput::Read() {
	// Read keyboard state
	bool pr = ReadKeyboard();

	// Collect inputs
	for (int i = 0; i < inputCount; i++) {
		inputs[i] = m_keyboardState[mappings[i]] & 0x80;
	}
}

void SimInput::SetMapping(int index, int code) {
	mappings[index] = code;
}

void SimInput::CleanUp() {
	// Release keyboard
	if (m_keyboard) { m_keyboard->Unacquire(); m_keyboard->Release(); m_keyboard = 0; }
	// Release direct input
	if (m_directInput) { m_directInput->Release(); m_directInput = 0; }
}

SimInput::SimInput(int count)
{
	inputCount = count;
}

SimInput::~SimInput()
{

}

