#!/bin/bash -xe

qemu-system-riscv32 -nographic -machine virt -bios build/bin/rv32imac_clang/virt/hello #-s -S
#qemu-system-riscv32 -nographic -machine virt -kernel build/bin/rv32imac_clang/virt/hello -bios none #-s -S

#riscv64-unknown-elf-objcopy -O binary build/bin/rv32imac_clang/virt/hello build/bin/rv32imac_clang/virt/hello.bin
#qemu-system-riscv32 -nographic -machine virt -bios build/bin/rv32imac_clang/virt/hello.bin #-s -S

