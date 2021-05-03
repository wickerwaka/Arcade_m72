#pragma once

struct SimClock
{

public:
	bool clk, old;

	SimClock::SimClock(int r);
	SimClock::~SimClock();
	void Tick();
	void Reset();
};