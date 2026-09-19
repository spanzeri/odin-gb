package odin_gb

import sdl "vendor:sdl3"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:os"
import "base:runtime"

GB_SCREEN_WIDTH  :: 160
GB_SCREEN_HEIGHT :: 144
SCREEN_SCALE :: 4

root_window: ^sdl.Window

check_bit :: #force_inline proc "contextless" (v: $T, biti: u32) -> bool {
    return ((v >> biti) & 0x1) != 0
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

    if sdl.Init({.AUDIO, .VIDEO, .GAMEPAD}) == false {
        log.error("Failed to start SDL with error: {}", string(sdl.GetError()))
    }
    log.error("Test")
    defer sdl.Quit()

    // create window and renderer
    renderer: ^sdl.Renderer
    sdl.CreateWindowAndRenderer(
        "odingb",
        GB_SCREEN_WIDTH * SCREEN_SCALE,
        GB_SCREEN_HEIGHT * SCREEN_SCALE,
        {},
        &root_window,
        &renderer,
    )
    if root_window == nil || renderer == nil {
        log.fatalf("Window creation failed with error: {}", string(sdl.GetError()))
    }
    defer {
        sdl.DestroyRenderer(renderer)
        sdl.DestroyWindow(root_window)
    }

    framebuffer := sdl.CreateTexture(renderer, .RGBA8888, .STREAMING, GB_SCREEN_WIDTH, GB_SCREEN_HEIGHT)
    if framebuffer == nil {
        log.fatalf("Failed to create framebuffer texture: {}", string(sdl.GetError()))
    }

    if init_res := core_init(); init_res != 0 {
        os.exit(cast(int)init_res)
    }
    defer core_shutdown()

    main_loop: for {
        event: sdl.Event
        for sdl.PollEvent(&event) {
            #partial switch event.type {
            case .QUIT: break main_loop
            }
        }

        core_run()

        rawpixels: rawptr
        pitch: i32
        if !sdl.LockTexture(framebuffer, nil, &rawpixels, &pitch) {
            log.fatalf("Failed to lock framebuffer texture {}", string(sdl.GetError()))
        }
        assert(pitch == GB_SCREEN_WIDTH * 4)

        pixels := cast(^[GB_SCREEN_HEIGHT][GB_SCREEN_WIDTH]u32)rawpixels

        for &row in pixels {
            for &col in row {
                col = 0xFF00FFFF
            }
        }

        sdl.UnlockTexture(framebuffer)

        sdl.RenderTexture(renderer, framebuffer, nil, nil)

        sdl.RenderPresent(renderer)
    }
}

