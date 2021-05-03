#include <stdio.h>
#include <stdlib.h>

unsigned char b[256];

main()
{
	int i;
	char *bs;

	read(0, b, 256);
	for (i = 0; i < 256; i++) {
		switch (b[i]) {
		case 0: bs = "0000"; break;
		case 1: bs = "0001"; break;
		case 2: bs = "0010"; break;
		case 3: bs = "0011"; break;
		case 4: bs = "0100"; break;
		case 5: bs = "0101"; break;
		case 6: bs = "0110"; break;
		case 7: bs = "0111"; break;
		case 8: bs = "1000"; break;
		case 9: bs = "1001"; break;
		case 10: bs = "1010"; break;
		case 11: bs = "1011"; break;
		case 12: bs = "1100"; break;
		case 13: bs = "1101"; break;
		case 14: bs = "1110"; break;
		case 15: bs = "1111"; break;
		}
		printf("	8'h%02x: d = 4'b%s;\n", i, bs);
	}

	exit(0);
}
