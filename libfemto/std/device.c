// See LICENSE for license details.

#include "femto.h"

void register_console(console_device_t *dev)
{
    console_dev = dev;
    if (dev->init) {
        dev->init();
    }
}

void register_poweroff(poweroff_device_t *dev)
{
    poweroff_dev = dev;
    if (dev->init) {
        dev->init();
    }
}

static int default_getchar()
{
#ifdef __riscv
    asm volatile("ebreak");
#else
    __builtin_trap();
#endif
    return 0;
}

static int default_putchar(int ch)
{
#ifdef __riscv
    asm volatile("ebreak");
#else
    __builtin_trap();
#endif
    return 0;
}

static void default_poweroff(int status)
{
#ifdef __riscv
    asm volatile("ebreak");
#else
    __builtin_trap();
#endif
    while (1) {
        asm volatile("" : : : "memory");
    }
}

console_device_t console_none = {
    NULL,
    default_getchar,
    default_putchar
};

poweroff_device_t poweroff_none = {
    NULL,
    default_poweroff,
};

console_device_t *console_dev = &console_none;
poweroff_device_t *poweroff_dev = &poweroff_none;
