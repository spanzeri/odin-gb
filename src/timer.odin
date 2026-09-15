package odin_gb

TimerRegisters :: struct {
    div, tima, tma, tac: u8
}

timer_registers := cast(^TimerRegisters)(&system_memory[0xFF04])

@(private="file")
sysclk := u16(0)

timer_interrupt_delay := u8(0)

timer_init :: proc "contextless" () {
    sysclk = 0xABCC
    timer_registers.div   = 0xAB
    timer_registers.tac   = 0
    timer_registers.tima  = 0
    timer_registers.tma   = 0
}

@(private="file")
check_clock_edges :: proc "contextless" (prev_sysclk: u16) {
    div_bit_4_prev := check_bit(timer_registers.div, 4)

    // Expose upper 8 bits
    timer_registers.div = cast(u8)(sysclk >> 8)

    div_bit_4_curr := check_bit(timer_registers.div, 4)

    if div_bit_4_prev && !div_bit_4_curr {
        // falling edge on div bit 4; tick APU
    }

    tac_timer_enabled := check_bit(timer_registers.tac, 2)
    if tac_timer_enabled {
        tac_clock_select := timer_registers.tac & 0b11

        TIMER_TAC_EDGE_BITS := [?]u32{ 9, 3, 5, 7 }

        tac_divider_bit := TIMER_TAC_EDGE_BITS[tac_clock_select]
        prev_edge := check_bit(prev_sysclk, tac_divider_bit)
        curr_edge := check_bit(sysclk, tac_divider_bit)
        if prev_edge && !curr_edge {
            // falling edge on tac
            timer_tick_tima()
        }
    }
}

timer_increase_div :: proc "contextless" (cycles: u32) {
    for _ in 0..<cycles {
        prev_sysclk := sysclk
        sysclk += 1
        check_clock_edges(prev_sysclk)
    }
}

timer_advance_clock :: proc "contextless" (cycles: u32) {
    if cpu_run_state == .Stopped {
        return
    }

    if timer_interrupt_delay > 0 {
        for _ in 0..<cycles {
            timer_interrupt_delay -= 1
            if timer_interrupt_delay == 0 {
                interrupt_raise_flag(.Timer)
                break
            }
        }
    }

    timer_increase_div(cycles)
}

timer_on_div_write :: proc "contextless" (value: u8) {
    prev_sysclk := sysclk
    sysclk = 0
    check_clock_edges(prev_sysclk)
}

timer_tick_tima :: proc "contextless" () {
    timer_registers.tima += 1
    if timer_registers.tima == 0 {
        timer_registers.tima = timer_registers.tma
        timer_interrupt_delay = 4
    }
}

