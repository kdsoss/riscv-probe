// See LICENSE for license details.

#include <stdio.h>
#include <stdlib.h>
#include <device.h>

void exit(int status)
{
    poweroff_dev->poweroff(status);
#ifndef __riscv
    asm volatile("1: b 1b");
#else
    asm volatile("1: j 1b");
#endif
    __builtin_unreachable();
}
