// See LICENSE for license details.

#include "femto.h"

enum {
	SIFIVE_TEST_FAIL = 0x3333,
	SIFIVE_TEST_PASS = 0x5555,
};

static volatile uint32_t *test;

static void sifive_test_init(config_data_t *cfg)
{
	test = (uint32_t *)(void *)get_config_data(cfg, SIFIVE_TEST_CTRL_ADDR);
}

static __attribute__((noreturn)) void sifive_test_poweroff()
{
    *test = SIFIVE_TEST_PASS;
    while (1) {
        asm volatile("");
    }
}

poweroff_device_t poweroff_sifive_test = {
	sifive_test_init,
	sifive_test_poweroff
};