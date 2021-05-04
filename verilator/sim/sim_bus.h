#pragma once
#include "verilated_heavy.h"

#ifndef _MSC_VER
#else
#define WIN32
#endif

struct SimBus {
public:

	IData* ioctl_addr;
	CData* ioctl_index;
	CData* ioctl_wait;
	CData* ioctl_download;
	CData* ioctl_upload;
	CData* ioctl_write;
	CData* ioctl_dout;
	CData* ioctl_din;

	void BeforeEval(void);
	void AfterEval(void);
	void ioctl_download_setfile(char* file, int index);

	SimBus(DebugConsole c);
	~SimBus();
};
