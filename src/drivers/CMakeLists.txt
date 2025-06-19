target_sources(tinybios PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/device.c
    ${CMAKE_CURRENT_SOURCE_DIR}/serial/serial.c
    ${CMAKE_CURRENT_SOURCE_DIR}/kbdctl/8042.c
    ${CMAKE_CURRENT_SOURCE_DIR}/pic_8259/pic.c
    ${CMAKE_CURRENT_SOURCE_DIR}/pit/pit.c
    ${CMAKE_CURRENT_SOURCE_DIR}/pit/pit_handler.S
    ${CMAKE_CURRENT_SOURCE_DIR}/pci/pci.c
    ${CMAKE_CURRENT_SOURCE_DIR}/pci/pci_util.c
    ${CMAKE_CURRENT_SOURCE_DIR}/cmos/cmos.c
    ${CMAKE_CURRENT_SOURCE_DIR}/ata/ata.c
    ${CMAKE_CURRENT_SOURCE_DIR}/ata/ata_util.c
)
