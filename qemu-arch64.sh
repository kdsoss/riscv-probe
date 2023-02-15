#!/bin/bash -xe

#qemu-system-aarch64 -m 128M -smp 1 -nographic -machine virt -machine virtualization=true -cpu cortex-a72 -s -S

#qemu-system-aarch64 -m 128M -smp 1 -nographic -machine virt -machine virtualization=true -cpu cortex-a72 -kernel ./build/bin/aarch64/qemu-aarch64/hello -s -S

aarch64-linux-gnu-objcopy -O binary ./build/bin/aarch64/qemu-aarch64/hello ./build/bin/aarch64/qemu-aarch64/hello.bin
qemu-system-aarch64 -m 128M -smp 1 -nographic -machine virt -machine virtualization=true -cpu cortex-a72 -kernel ./build/bin/aarch64/qemu-aarch64/hello.bin #-s -S
