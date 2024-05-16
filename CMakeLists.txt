cmake_minimum_required(VERSION 3.6)
project(tinybios LANGUAGES C ASM VERSION 0.5)

find_program(dd NAMES dd HINTS /usr/bin /usr/local/bin /bin)
find_program(clang NAMES clang clang16 HINTS /usr/bin /usr/local/bin /bin)

set(target_mainboard "qemu" CACHE STRING "Currently we only support qemu for now")
set(target_cpu "x86-64" CACHE STRING "We only support x86-64 cpus for now")
set(CC clang)
set(ASMFLAGS -m16)

add_executable(tinybios 
    src/reset.S
    src/cpu/cache.S
    src/c_entry.c
)

# add_subdirectory(src/mainboards/${target_mainboard})

add_custom_command(
    TARGET tinybios
    POST_BUILD
    COMMENT "Building BIOS Image from ELF file" 
    COMMAND objcopy -j .data -j .text -j .reset -O binary tinybios.elf tinybios.bin
)

target_compile_options(tinybios PRIVATE
    -Wall -Wextra -Wpedantic 
    -ffreestanding -fno-stack-protector
    -fno-builtin -nostdinc -nostdlib
    -I./src/include
    -masm=intel
    -march=${target_cpu}
    ${ASMFLAGS}
)

target_link_options(tinybios PRIVATE
    -nostdlib -m16 -Wl,--script=${CMAKE_CURRENT_SOURCE_DIR}/linker.conf
)

set_target_properties(tinybios PROPERTIES OUTPUT_NAME tinybios.elf)


