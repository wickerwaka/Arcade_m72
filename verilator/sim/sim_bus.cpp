#include "sim_bus.h"
#include "sim_console.h"
#include "verilated_heavy.h"

#ifndef _MSC_VER
#else
#define WIN32
#endif

static DebugConsole console;

FILE* ioctl_file = NULL;
int ioctl_next_addr = 0x0;

IData* ioctl_addr = NULL;
CData* ioctl_index = NULL;
CData* ioctl_wait = NULL;
CData* ioctl_download = NULL;
CData* ioctl_upload = NULL;
CData* ioctl_wr = NULL;
CData* ioctl_dout = NULL;
CData* ioctl_din = NULL;

void SimBus::ioctl_download_setfile(char* file, int index)
{
	ioctl_next_addr = -1;
	*ioctl_addr = ioctl_next_addr;
	*ioctl_index = index;
	ioctl_file = fopen(file, "rb");
	if (!ioctl_file) {
		console.AddLog("error opening %s\n", file);
	}
}
int nextchar = 0;
void SimBus::BeforeEval()
{
	if (ioctl_file) {
		console.AddLog("ioctl_download addr %x  ioctl_wait %x", *ioctl_addr, *ioctl_wait);
		if (*ioctl_wait == 0) {
			*ioctl_download = 1;
			*ioctl_wr = 1;
			if (feof(ioctl_file)) {
				fclose(ioctl_file);
				ioctl_file = NULL;
				*ioctl_download = 0;
				*ioctl_wr = 0;
				console.AddLog("finished upload\n");
			}
			if (ioctl_file) {
				int curchar = fgetc(ioctl_file);
				if (feof(ioctl_file) == 0) {
					nextchar = curchar;
					console.AddLog("ioctl_download: dout %x \n", *ioctl_dout);
					ioctl_next_addr++;
				}
			}
		}
	}
	else {
		ioctl_download = 0;
		ioctl_wr = 0;
	}
}

void SimBus::AfterEval()
{
	*ioctl_addr = ioctl_next_addr;
	*ioctl_dout = (unsigned char)nextchar;
	if (ioctl_file) {
		console.AddLog("ioctl_download %x wr %x dl %x\n", *ioctl_addr, *ioctl_wr, *ioctl_download);
	}
}


SimBus::SimBus(DebugConsole c) {
	console = c;
	ioctl_addr = NULL;
	ioctl_index = NULL;
	ioctl_wait = NULL;
	ioctl_download = NULL;
	ioctl_upload = NULL;
	ioctl_wr = NULL;
	ioctl_dout = NULL;
}

SimBus::~SimBus() {

}