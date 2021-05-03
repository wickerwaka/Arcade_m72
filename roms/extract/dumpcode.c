#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>

unsigned char b[4][2048];

int read_roms(int ac, char *av[])
{
	int i, f, r;
	char *fn;

	for (i = 0; i < 4; i++) {
		fn = av[i];
		f = open(fn, O_RDONLY);
		if (f < 0) perror(fn);
		r = read(f, &b[i][0], 2048);
		close(f);
	}
}

main(int argc, char *argv[])
{
	int i, j;

	if (argc > 1 && argv[1][0] == '-' && argv[1][1] == 'c') {
		read_roms(argc-2, argv+2);
		// case
		printf("  // centipede\n");
		printf("  case (a)\n");
		for (j = 0; j < 4; j++) {
			printf("\t// %s\n", argv[2+j]);
			for (i = 0; i < 2048; i++) {
				printf("\t13'h%03x: q = 8'h%02x; // 0x%03x\n", (j*2048)+i, b[j][i], (j*2048)+i);
			}
		}
		printf("  endcase\n");
	} else {
		read_roms(argc, argv);
		// initial block
		printf("initial begin\n");
		printf("\t// centipede\n");

		for (j = 0; j < 4; j++) {
			for (i = 0; i < 2048; i++) {
				printf("\trom[%d] = 8'h%02x; // 0x%04x\n", (j*2048)+i, b[j][i], (j*2048)+i);
			}
		}
		
		printf("end\n");
	}

	exit(0);
}
