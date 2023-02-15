#CROSS_COMPILE      ?= riscv64-unknown-elf-

AR                 = $(CROSS_COMPILE)ar

CFLAGS             = -fcommon -ffunction-sections -fdata-sections \
		     -ffreestanding -mno-relax
LDFLAGS            = -nostartfiles -nostdlib -nostdinc -pie \
                     -Wl,--nmagic -Wl,--gc-sections -Wl,--build-id=none \
		     -fuse-ld=lld #-Wl,--apply-dynamic-relocs

INCLUDES           = -Ienv/common

#
# Compiler configurations and target environment definitions
#

subdirs            = examples

libs               = libfemto

configs            = rv32imac rv32imac_clang rv32imac_piccolo rv64imac_piccolo aarch64

CC_rv32imac        = riscv64-unknown-elf-gcc
CFLAGS_rv32imac    = -Os -march=rv32imac -mabi=ilp32 -Ienv/common/rv32
LDFLAGS_rv32imac   =

CC_rv32imac_clang        = $(CROSS_COMPILE)clang
CFLAGS_rv32imac_clang    = -Os --target=riscv32 -march=rv32imac -mabi=ilp32 -Ienv/common/rv32
LDFLAGS_rv32imac_clang   =

CC_rv32imac_piccolo        = $(CROSS_COMPILE)clang
CFLAGS_rv32imac_piccolo    = -Os --target=riscv32 -march=rv32imac -mabi=ilp32 -Ienv/common/rv32 -DPICCOLO
LDFLAGS_rv32imac_piccolo   =

CC_rv64imac_piccolo        = $(CROSS_COMPILE)clang
CFLAGS_rv64imac_piccolo    = -Os --target=riscv64 -march=rv64imac -mabi=lp64 -Ienv/common/rv64 -DPICCOLO
LDFLAGS_rv64imac_piccolo   =

CC_rv64imac        = $(CROSS_COMPILE)gcc
CFLAGS_rv64imac    = -Os -march=rv64imac -mabi=lp64  -Ienv/common/rv64
LDFLAGS_rv64imac   =

CC_aarch64        = $(CROSS_COMPILE)clang
CFLAGS_aarch64    = -Os --target=aarch64-unknown-linux-gnu -mgeneral-regs-only -Ienv/common/aarch64 -DPICCOLO
LDFLAGS_aarch64   =
ARCH_aarch64      = aarch64

define objs =
ifeq ($(ARCH_$(1)),)
libfemto_arch_$(1) = riscv
else
libfemto_arch_$(1) = $(ARCH_$(1))
endif
libfemto_dirs_$(1) = libfemto/std libfemto/drivers libfemto/arch/$$(libfemto_arch_$(1))
libfemto_src_$(1)  = $$(sort $$(foreach d,$$(libfemto_dirs_$(1)),$$(wildcard $$(d)/*.c)))
libfemto_asm_$(1)  = $$(sort $$(foreach d,$$(libfemto_dirs_$(1)),$$(wildcard $$(d)/*.s)))
libfemto_objs_$(1) = $$(patsubst %.s,%.o,$$(libfemto_asm_$(1))) \
                     $$(patsubst %.c,%.o,$$(libfemto_src_$(1)))
endef

$(foreach c,$(configs),$(eval $(call objs,$(c))))


targets0            = rv32imac:virt rv32imac_clang:virt \
			rv32imac_piccolo:piccolo rv32imac_piccolo:gfe \
			rv64imac_piccolo:piccolo rv64imac_piccolo:gfe

targets	= \
		rv32imac_clang:virt aarch64:rockchip aarch64:qemu-aarch64

targets1            = rv32imac:default \
                     rv64imac:default \
                     rv32imac:spike \
                     rv64imac:spike \
                     rv32imac:virt \
                     rv64imac:virt \
                     rv32imac:qemu-sifive_e \
                     rv64imac:qemu-sifive_e \
                     rv32imac:qemu-sifive_u \
                     rv64imac:qemu-sifive_u \
                     rv32imac:coreip-e2-arty

#
# make rules
#

all: all_programs

clean:
	rm -fr build

backup: clean
	tar czf ../$(shell basename $(shell pwd)).tar.gz .

%.lds: %.lds.S
	$(CC) -E -P -D__ASSEMBLY__ -DLINKER_SCRIPT -o $@ $<
#
# To view commands use: make V=1
#

ifdef V
cmd = @mkdir -p $2 ; echo "$3"; $3
else
cmd = @echo "$1"; mkdir -p $2 ; $3
endif

#
# Build system functions to generate pattern rules for all configs
#

define pattern =
build/obj/$(2)/%.o: %.$(3)
	$(call cmd,$(1).$(2) $$@,$$(@D),$(CC_$(2)) $(CFLAGS_$(2)) $(CFLAGS) \
	$$(INCLUDES) -c $$^ -o $$@)
endef

$(foreach c,$(configs),$(eval $(call pattern,CC,$(c),c)))
$(foreach c,$(configs),$(eval $(call pattern,AS,$(c),s)))

#
# Build system functions to generate library rules for all configs
#

define archive =
build/lib/$(2)/$(3).a: $(addprefix build/obj/$(2)/,$($(3)_objs_$(2)))
	$(call cmd,$(1).$(2) $$@,$$(@D),$(AR) cr $$@ $$^)
LIBS_$(2) += build/lib/$(2)/$(3).a
endef

define lib =
$(foreach c,$(configs),$(eval $(call archive,AR,$(c),$(1))))
INCLUDES += -I$(1)/include
endef

$(foreach l,$(libs),$(eval $(call lib,$(l))))

#
# Build system functions to generate build rules for all subdirs
#

sub_makes := $(foreach dir,$(subdirs),$(wildcard ${dir}/*/rules.mk))
$(foreach makefile,$(sub_makes),$(eval include $(makefile)))
sub_dirs := $(foreach m,$(sub_makes),$(m:/rules.mk=))
module_name = $(lastword $(subst /, ,$(1)))
module_objs = $(addprefix build/obj/$(3)/,$(addprefix $(2)/,$($(1)_objs)))
config_arch = $(word 1,$(subst :, ,$(1)))
config_env = $(word 2,$(subst :, ,$(1)))

define rule =
build/bin/$(3)/$(4)/$(1): \
build/obj/$(3)/env/$(4)/crt.o build/obj/$(3)/env/$(4)/setup.o $(2) $$(LIBS_$(3)) \
	env/$(4)/default.lds
	$$(call cmd,LD.$(3) $$@,$$(@D),$(CC_$(3)) $(CFLAGS_$(3)) $$(CFLAGS) \
	$$(LDFLAGS_$(3)) $$(LDFLAGS) -T env/$(4)/default.lds $$(filter-out env/$(4)/default.lds, $$^) -o $$@)
endef

define module =
program_names += $(foreach cfg,$(targets),build/bin/$(call \
  config_arch,$(cfg))/$(call config_env,$(cfg))/$(1))

$(foreach cfg,$(targets),$(eval $(call rule,$(1),$(call \
  module_objs,$(1),$(2),$(call config_arch,$(cfg))),$(call \
  config_arch,$(cfg)),$(call config_env,$(cfg)))))
endef

$(foreach d,$(sub_dirs),$(eval $(call module,$(call module_name,$(d)),$(d))))

all_programs: $(program_names)
