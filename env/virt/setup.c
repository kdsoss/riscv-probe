// See LICENSE for license details.

#include "femto.h"

auxval_t __auxv[] = {
    { RISCV_HTIF_BASE_ADDR, 0 },
    { UART0_CLOCK_FREQ,         25000000   },
    { UART0_BAUD_RATE,          115200     },
    { NS16550A_UART0_CTRL_ADDR, 0x62300000 },
    { SIFIVE_TEST_CTRL_ADDR,    0x100000   },
    { 0, 0 }
};

extern uint64_t tohost;
extern uint64_t fromhost;

void arch_setup()
{
	__auxv[0].val = (uintptr_t)(&tohost < &fromhost ? &tohost : &fromhost);
	//register_console(&console_htif);
	register_console(&console_ns16550a);
	register_poweroff(&poweroff_htif);
	//register_poweroff(&poweroff_sifive_test);
}

