package odin_gb

import "core:log"
import "core:os"
import "core:strings"

core_clock_counter: u32
core_quit_requested: bool

core_init :: proc () -> i32 {
    if len(os.args) > 1 && strings.ends_with(os.args[1], ".gb") {
        log.infof("Loading cart from command argument: {}", os.args[1])
        if !cart_load(os.args[1]) {
            log.errorf("    Failed to read ROM")
            os.exit(1)
        }
    } else {
        cart_open_file()
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

