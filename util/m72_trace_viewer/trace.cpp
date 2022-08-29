#include "trace.h"

std::vector<TraceRecord> read_trace(const std::string& filename)
{
	FILE* fp = fopen(filename.c_str(), "rb");

	fseek(fp, 0, SEEK_END);
	uint64_t size = _ftelli64(fp);
	fseek(fp, 0, SEEK_SET);

	uint16_t cs = 0;

	uint32_t work[256];

	std::vector<TraceRecord> out;
	out.reserve(size / 4);
	
	while (true)
	{
		int r = fread(work, 4, 256, fp);
		if (r != 256) break;

		for (int i = 0; i < 256; i++)
		{
			TraceRecord record;
			uint32_t rec = work[i];
			if ((rec & 0xc0000000) == 0x40000000)
			{
				uint16_t data = rec & 0xffff;
				uint16_t addr = (rec >> 16) & 0xfff;
				uint8_t we = (rec >> 28) & 3;

				if (we == 0)
				{
					record.type = CPU_MEM_READ;
					record.cpu_read.address = addr;
					record.cpu_read.value = data;
				}
				else if (we == 1)
				{
					record.type = CPU_MEM_WRITE;
					record.cpu_write.address = addr;
					record.cpu_write.value = data & 0xff;
					record.cpu_write.size = 1;
				}
				else if (we == 2)
				{
					record.type = CPU_MEM_WRITE;
					record.cpu_write.address = addr + 1;
					record.cpu_write.value = (data >> 8) & 0xff;
					record.cpu_write.size = 1;
				}
				else
				{
					record.type = CPU_MEM_WRITE;
					record.cpu_write.address = addr;
					record.cpu_write.value = data;
					record.cpu_write.size = 2;
				}
				out.push_back(record);
			}
			else if ((rec & 0xc0000000) == 0x80000000)
			{
				uint8_t data = rec & 0xff;
				uint16_t addr = (rec >> 8) & 0xfff;
				bool we = (rec >> 20) & 1;
				if (we)
					record.type = MCU_MEM_WRITE;
				else
					record.type = MCU_MEM_READ;
				record.mcu_mem.address = addr;
				record.mcu_mem.value = data;
				out.push_back(record);
			}
			else if ((rec >> 24) == 0xc0)
			{
				cs = rec & 0xffff;
			}
			else if ((rec >> 24) == 0xc1)
			{
				uint16_t addr = rec & 0xffff;
				uint8_t opcode = (rec >> 16) & 0xff;
				record.type = CPU_IP;
				record.cpu_ip.address = addr + (cs << 4);
				record.cpu_ip.opcode = opcode;
				out.push_back(record);
			}
			else if ((rec >> 24) == 0xc2)
			{
				uint16_t addr = rec & 0xffff;
				record.type = MCU_ROM;
				record.mcu_rom.address = addr;
				out.push_back(record);
			}
		}
	}

	fclose(fp);

	return out;
}