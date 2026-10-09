package odin_gb

import "core:log"
import "core:os"
import "core:strings"
import "core:math"

import sdl "vendor:sdl3"

core_clock_counter: u32
core_quit_requested: bool

debug_gfx_ctx, render_gfx_ctx: GfxContext

CPU_FRAME_TIME_NS := cast(u64)math.round(1e9 / 59.73)
frame_start_ns: u64

core_init :: proc () {
    if sdl.Init({.AUDIO, .VIDEO, .GAMEPAD}) == false {
        log.error("Failed to start SDL with error: {}", string(sdl.GetError()))
    }

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

    core_init_gfx_contexts()
    ppu_init()
    timer_init()
}

core_run :: proc () {
    frame_start_ns = sdl.GetTicksNS()

    cpu_reset()
    ppu_reset()
    timer_init()

    for !core_quit_requested {
        cpu_tick()
    }
}

core_on_frame :: proc () {
    event: sdl.Event
    for sdl.PollEvent(&event) {
        #partial switch event.type {
        case .QUIT: fallthrough
        case .WINDOW_CLOSE_REQUESTED:
            core_quit_requested = true
        case .KEY_DOWN: fallthrough
        case .KEY_UP:
            down := (event.type == .KEY_DOWN)
            core_on_key_press(event.key.scancode, down)
        }
    }

    frame_end_ns := sdl.GetTicksNS()
    elapsed_ns := frame_end_ns - frame_start_ns

    if elapsed_ns < CPU_FRAME_TIME_NS {
        sdl.DelayNS(CPU_FRAME_TIME_NS - elapsed_ns)
    }

    frame_end_ns = sdl.GetTicksNS()
    elapsed_ns = frame_end_ns - frame_start_ns
    frame_start_ns = frame_end_ns
}

core_shutdown :: proc () {
    gfx_context_delete(&debug_gfx_ctx)
    gfx_context_delete(&render_gfx_ctx)
    sdl.Quit()
}

core_advance_cpu_clocks :: proc (clocks: u32) {
    timer_advance_clock(clocks)
    ppu_advance_clock(clocks)
    core_clock_counter += clocks

    if core_clock_counter >= 70224 {
        if !lcdc_enable_lcd() {
            core_on_frame()
        }
        core_clock_counter = 0
    }
}

core_init_gfx_contexts :: proc() {
    debug_ok, render_ok: bool
    debug_gfx_ctx, debug_ok = gfx_context_make(PPU_DEBUG_WIDTH, PPU_DEBUG_HEIGHT, PPU_DEBUG_SCALE, "Debug")
    render_gfx_ctx, render_ok = gfx_context_make(LCD_PIXEL_WIDTH, LCD_PIXEL_HEIGHT, PPU_RENDER_SCALE, "odin-gb")

    if !debug_ok do os.exit(1)
    if !render_ok do os.exit(1)

    COLOR_BLACK := sdl.Color{0, 0, 0, 0xFF}

    gfx_clear(debug_gfx_ctx, COLOR_BLACK)
    gfx_clear(render_gfx_ctx, COLOR_BLACK)

    gfx_update(debug_gfx_ctx)
    gfx_update(render_gfx_ctx)
}

core_get_root_window :: proc() -> ^sdl.Window {
    return render_gfx_ctx.window
}

@(private="file")
core_on_key_press :: proc (sym: sdl.Scancode, down: bool) {
    #partial switch sym {
    case .W: joypad_on_dpad_up(down)
    case .A: joypad_on_dpad_left(down)
    case .S: joypad_on_dpad_down(down)
    case .D: joypad_on_dpad_right(down)

    case .J: joypad_on_button_a(down)
    case .K: joypad_on_button_b(down)

    case .SPACE: joypad_on_button_select(down)
    case .RETURN: joypad_on_button_start(down)

    case .ESCAPE:
        when ODIN_DEBUG {
            if down do core_quit_requested = true
        }
    }
}

