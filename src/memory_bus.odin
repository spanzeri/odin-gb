package odin_gb

MEMORY_SIZE :: 64 * 1024

system_memory: [MEMORY_SIZE]u8

ADDR_IO_IF :: 0xFF0F    // Interrupt flag
ADDR_IO_IE :: 0xFFFF    // Interrupt enable

memory_bus_read :: proc "contextless" (addr: u16) -> u8 {
    return cart_data[addr]
}

memory_bus_write :: proc "contextless" (addr: u16, value: u8) {
}
