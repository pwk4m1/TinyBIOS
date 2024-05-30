target_sources(tinybios PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/memory_init.S
    ${CMAKE_CURRENT_SOURCE_DIR}/superio/superio.c
)
