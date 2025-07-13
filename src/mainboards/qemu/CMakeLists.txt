target_sources(tinybios PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/memory_init.S
    ${CMAKE_CURRENT_SOURCE_DIR}/superio/superio.c
    ${CMAKE_CURRENT_SOURCE_DIR}/fwcfg/fwcfg.c
    ${CMAKE_CURRENT_SOURCE_DIR}/memory_init_late.c
)
