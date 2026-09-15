package odin_gb

core_clock_counter: u32
core_quit_requested: bool

core_init :: proc () -> i32 {
    // Load card
    if !cart_load("tetris.gb") {
        return -1
    }
    cart_print_info()

    return 0
}

core_run :: proc () {
    cpu_reset()
    timer_init()

    for !core_quit_requested {
        cpu_tick()
    }
}

core_shutdown :: proc () {
}

core_advance_cpu_clocks :: proc "contextless" (clocks: u32) {
    timer_advance_clock(clocks)
    core_clock_counter += clocks
}

