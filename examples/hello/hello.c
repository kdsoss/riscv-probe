#include <stdio.h>

#define FREQ	25000000
#define HZ	(FREQ/8)

void sleep(int sec)
{
	volatile int count = sec * HZ;
	while (count--);
}

int main(int argc, char **argv)
{
	int count = 0;
	for (;;) {
		printf("Hello Arty: %d\n", count++);
		sleep(1);
	}
}
