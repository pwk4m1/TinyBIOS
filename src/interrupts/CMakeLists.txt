target_sources(tinybios PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/${target_cpu}/idt.c
    ${CMAKE_CURRENT_SOURCE_DIR}/${target_cpu}/default_int_handler.S
    ${CMAKE_CURRENT_SOURCE_DIR}/${target_cpu}/default_int_handler.c

)
