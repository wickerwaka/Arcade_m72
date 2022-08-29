#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <vector>
#include <string>

enum RecordType : uint8_t
{
	CPU_MEM_READ,
	CPU_MEM_WRITE,
	MCU_MEM_READ,
	MCU_MEM_WRITE,
	CPU_IP,
	MCU_ROM,
};

struct CPUMemRead
{
	uint16_t address;
	uint16_t value;
};

struct CPUMemWrite
{
	uint8_t size;
	uint16_t address;
	uint16_t value;
};

struct MCUMem
{
	uint16_t address;
	uint8_t value;
};

struct CPUIP
{
	uint8_t opcode;
	uint32_t address;
};

struct MCUROM
{
	uint16_t address;
};

struct TraceRecord
{
	RecordType type;
	union
	{
		CPUMemRead cpu_read;
		CPUMemWrite cpu_write;
		MCUMem mcu_mem;
		CPUIP cpu_ip;
		MCUROM mcu_rom;
	};
};

std::vector<TraceRecord> read_trace(const std::string& filename);