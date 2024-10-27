cmake_minimum_required(VERSION 3.10)
project(tinybios LANGUAGES C ASM VERSION 0.5)

find_program(dd NAMES dd HINTS /usr/bin /usr/local/bin /bin)
find_program(clang NAMES clang clang16 HINTS /usr/bin /usr/local/bin /bin)

set(target_mainboard "qemu" CACHE STRING "Currently we only support qemu for now")
set(target_cpu "x86-64" CACHE STRING "We only support x86-64 cpus for now")
set(CC clang)

# These source files are used by _all_ versions of x86 bios of ours
#
add_executable(tinybios 
    src/cpu/gdt.S
    src/cpu/init.S

    src/interrupts/interrupts.S
    src/interrupts/ivt.c

    src/drivers/serial/serial.c
    src/drivers/kbdctl/8042.c

    src/mm/slab.c

    src/c_entry.c
    src/console.c
    src/reset.S
)

# Helper stuff
add_subdirectory(src/stdlib)

# These sources are mainboard dependant
#
add_subdirectory(src/mainboards/${target_mainboard})

add_custom_command(
    TARGET tinybios
    POST_BUILD
    COMMENT "Building BIOS Image from ELF file" 
    COMMAND objcopy -j .rom_text -j .data -j .text -j .reset -O binary tinybios.elf tinybios.bin
)

add_custom_target(run
    COMMAND qemu-system-x86_64 -bios tinybios.bin -serial stdio
    DEPENDS tinybios.bin
    USES_TERMINAL
)

add_custom_target(log-int
    COMMAND qemu-system-x86_64 -bios tinybios.bin -d int
    DEPENDS tinybios.bin
    USES_TERMINAL
)

add_custom_target(log-asm
    COMMAND qemu-system-x86_64 -bios tinybios.bin -d in_asm
    DEPENDS tinybios.bin
    USES_TERMINAL
)


add_custom_target(debug
    COMMAND qemu-system-x86_64 -S --daemonize -s -bios tinybios.bin
    COMMAND gdb -ix ${CMAKE_CURRENT_SOURCE_DIR}/gdbinit
    DEPENDS tinybios.bin
    USES_TERMINAL
)

target_include_directories(tinybios SYSTEM PUBLIC 
    "src/include"
)

target_compile_options(tinybios PUBLIC 
    -Wall -Wextra
    -nostdlib
    -ibuiltininc
    -ffreestanding
    -masm=intel
    -m32
    -fno-pic
    -std=gnu2x
    -D TARGET_MAINBOARD=${target_mainboard}
    -march=${target_cpu}
)

target_link_options(tinybios PUBLIC 
    -nostdlib -m32 -Wl,--script=${CMAKE_CURRENT_SOURCE_DIR}/linker.conf
)

set_target_properties(tinybios PROPERTIES OUTPUT_NAME tinybios.elf)


