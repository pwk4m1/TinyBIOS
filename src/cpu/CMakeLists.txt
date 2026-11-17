target_sources(tinybios PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/${target_cpu}/init.S
    ${CMAKE_CURRENT_SOURCE_DIR}/${target_cpu}/gdt.S
)
