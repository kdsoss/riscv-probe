#include <stdio.h>

int main(int argc, char **argv)
{
	int i = 0;
	for (;;) {
		printf("hello: %d\r\n", i++);
		for (int count = 0; count < 100000000; count ++) {
			asm("");
		}
	}
}
