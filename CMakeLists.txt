cmake_minimum_required(VERSION 3.6)
project(tinybios LANGUAGES C ASM VERSION 0.5)

find_program(dd NAMES dd HINTS /usr/bin /usr/local/bin /bin)
find_program(clang NAMES clang clang16 HINTS /usr/bin /usr/local/bin /bin)

set(target_mainboard "qemu" CACHE STRING "Currently we only support qemu for now")
set(target_cpu "x86-64" CACHE STRING "We only support x86-64 cpus for now")
set(CC clang)
set(ASMFLAGS -m16)

# These source files are used by _all_ versions of x86 bios of ours
#
add_executable(tinybios 
    src/reset.S
    src/cpu/gdt32.S
    src/cpu/init.S
    src/c_entry.c
    src/drivers/serial/serial.c
)

# These sources are mainboard dependant
#
add_subdirectory(src/mainboards/${target_mainboard})

add_custom_command(
    TARGET tinybios
    POST_BUILD
    COMMENT "Building BIOS Image from ELF file" 
    COMMAND objcopy -j .data -j .text -j .reset -O binary tinybios.elf tinybios.bin
)

target_include_directories(tinybios PUBLIC 
    src/include
)

target_compile_options(tinybios PUBLIC 
    -Wall -Wextra
    -fno-builtin -nostdinc -nostdlib
    -ffreestanding
    -fno-stack-protector
    -masm=intel
    -m16
    -D TARGET_MAINBOARD=${target_mainboard}
    -march=${target_cpu}
    ${ASMFLAGS}
)

target_link_options(tinybios PUBLIC 
    -nostdlib -m16 -Wl,--script=${CMAKE_CURRENT_SOURCE_DIR}/linker.conf
)

set_target_properties(tinybios PROPERTIES OUTPUT_NAME tinybios.elf)


