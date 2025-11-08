cmake_minimum_required(VERSION 3.10)
project(tinybios LANGUAGES C ASM VERSION 0.5)

find_program(dd NAMES dd HINTS /usr/bin /usr/local/bin /bin)
find_program(clang-19 NAMES clang clang-19 HINTS /usr/bin /usr/local/bin /bin)

set(target_mainboard "qemu" CACHE STRING "Currently we only support qemu for now")
set(target_cpu "x86-64" CACHE STRING "We only support x86-64 cpus for now")
set(CC distcc clang)

# These source files are used by _all_ versions of x86 bios of ours
#
add_executable(tinybios 
    src/cpu/gdt.S
    src/cpu/init.S

    src/mm/slab.c
    src/mm/malloc.c

    src/interrupts/idt.c
    src/interrupts/default_int_handler.c

    src/romcall/romcall.c

    src/stacks/ctx.c
    src/stacks/ctx.S

    src/c_entry.c
    src/panic.c
    src/post.c
    src/console.c
    src/reset.S
)

# Device drivers
add_subdirectory(src/drivers)

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
    COMMAND qemu-system-x86_64 -bios tinybios.bin -device piix3-ide,id=ide -drive id=disk,file=${CMAKE_CURRENT_SOURCE_DIR}/test_disk,format=raw,if=none -device ide-hd,drive=disk,bus=ide.0
    DEPENDS tinybios.bin
    USES_TERMINAL
)

add_custom_target(log-int
    COMMAND qemu-system-x86_64 -bios tinybios.bin -d int -device piix3-ide,id=ide -drive id=disk,file=${CMAKE_CURRENT_SOURCE_DIR}/test_disk,format=raw,if=none -device ide-hd,drive=disk,bus=ide.0
    DEPENDS tinybios.bin
    USES_TERMINAL
)

add_custom_target(log-asm
    COMMAND qemu-system-x86_64 -bios tinybios.bin -d in_asm -device piix3-ide,id=ide -drive id=disk,file=${CMAKE_CURRENT_SOURCE_DIR}/test_disk,format=raw,if=none -device ide-hd,drive=disk,bus=ide.0
    DEPENDS tinybios.bin
    USES_TERMINAL
)

add_custom_target(bochs
    COMMAND bochs -f ../bochsrc.txt
    DEPENDS tinybios.bin
    USES_TERMINAL
)

add_custom_target(debug
    COMMAND qemu-system-x86_64 -S --daemonize -s -bios tinybios.bin -device piix3-ide,id=ide -drive id=disk,file=${CMAKE_CURRENT_SOURCE_DIR}/test_disk,format=raw,if=none -device ide-hd,drive=disk,bus=ide.0
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
    -fno-pic
    -std=gnu2x
    -D TARGET_MAINBOARD=${target_mainboard}
    -march=${target_cpu}
)

target_link_options(tinybios PUBLIC 
    -nostdlib -no-pie -Wl,--script=${CMAKE_CURRENT_SOURCE_DIR}/linker.conf
)

set_target_properties(tinybios PROPERTIES OUTPUT_NAME tinybios.elf)


