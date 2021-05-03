#pragma once

class SimClock
{

public:
	bool clk, old;

	SimClock::SimClock(int r);
	SimClock::~SimClock();
	void Tick();
	void Reset();

private:
	int ratio, count;
};