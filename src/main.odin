package odin_gb

import "core:fmt"
import "core:log"
import "core:mem"
import "base:runtime"

GB_SCREEN_WIDTH  :: 160
GB_SCREEN_HEIGHT :: 144
SCREEN_SCALE :: 4

check_bit :: #force_inline proc "contextless" (v: $T, biti: u32) -> bool {
    return ((v >> biti) & 0x1) != 0
}

change_bit :: #force_inline proc "contextless" (v: ^$T, value: u8, biti: u32) {
    mask := u8(1) << biti
    v^ = (v^ & ~mask) | (value & 0b1) << biti
}

main :: proc() {
    context.logger = log.create_console_logger()
    defer log.destroy_console_logger(context.logger)
    defer debug_log_close()

    when ODIN_DEBUG {
        track: mem.Tracking_Allocator
        mem.tracking_allocator_init(&track, context.allocator)
        defer mem.tracking_allocator_destroy(&track)
        context.allocator = mem.tracking_allocator(&track)

        defer {
            if len(track.allocation_map) > 0 {
                fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
                for _, entry in track.allocation_map {
                    fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
                }
            }
        }
    }

    core_init()
    defer core_shutdown()

    core_run()
}


