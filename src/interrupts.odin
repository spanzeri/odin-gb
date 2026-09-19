package odin_gb

INTERRUPT_MASK :: u8(0x1F)

Interrupt :: enum u8 {
    VBlank = 0,
    Stat,
    Timer,
    Serial,
    Joypad,
}

interrupt_master_enabled: bool
interrupt_enable_ime_delay: u8

INTERRUPT_ADDRESSES := [Interrupt]u16{
    .VBlank = 0x0040,
    .Stat   = 0x0048,
    .Timer  = 0x0050,
    .Serial = 0x0058,
    .Joypad = 0x0060,
}

interrupt_service_routine :: proc () {
    if cpu_run_state == .Stopped {
        return
    }

    pending := interrupt_pending()
    if pending == 0 {
        return
    }

    if cpu_run_state == .Halted {
        core_advance_cpu_clocks(4)
        cpu_run_state = .Running
    }
    if !interrupt_master_enabled {
        return
    }

    interrupt_jump_to()
}

interrupt_mask :: proc "contextless" (interrupt: Interrupt) -> u8 {
    return u8(1) << u8(interrupt)
}

interrupt_raise_flag :: proc "contextless" (interrupt: Interrupt) {
    system_memory[ADDR_IO_IF] |= (1 << interrupt)
}

interrupt_flag_write :: proc "contextless" (value: u8) {
    system_memory[ADDR_IO_IF] = value
}

interrupt_pending :: proc "contextless" () -> u8 {
    return system_memory[ADDR_IO_IE] & system_memory[ADDR_IO_IF] & INTERRUPT_MASK
}

interrupt_select :: proc "contextless" (pending: u8) -> Interrupt {
    for i in Interrupt {
        if pending & interrupt_mask(i) != 0 {
            return i
        }
    }
    unreachable()
}

interrup_acknowledge :: proc "contextless" (interrupt: Interrupt) {
    system_memory[ADDR_IO_IF] &= ~interrupt_mask(interrupt)
}

@(private = "file")
interrupt_jump_to :: proc () {
    interrupt_master_enabled = false
    interrupt_enable_ime_delay = 0
    cpu_execute_halt_bug()

    core_advance_cpu_clocks(4)

    cpu_registers.sp -= 1
    core_advance_cpu_clocks(4)

    pchi := cast(u8)((cpu_registers.pc & 0xFF00) >> 8)
    pclo := cast(u8)( cpu_registers.pc & 0x00FF)
    memory_bus_write(cpu_registers.sp, pchi)
    cpu_registers.sp -= 1
    core_advance_cpu_clocks(4)

    vector := u16(0)
    pending := interrupt_pending()
    if pending != 0 {
        selected_interrupt := interrupt_select(pending)
        vector = INTERRUPT_ADDRESSES[selected_interrupt]
        interrup_acknowledge(selected_interrupt)
    }

    memory_bus_write(cpu_registers.sp, pclo)
    core_advance_cpu_clocks(4)

    cpu_registers.pc = vector
    core_advance_cpu_clocks(4)
}

