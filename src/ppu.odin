package odin_gb

import "core:slice"

import sdl "vendor:sdl3"

LCD_PIXEL_WIDTH :: 160
LCD_PIXEL_HEIGHT :: 144
PPU_RENDER_SCALE :: 5

PPU_DEBUG_WIDTH, PPU_DEBUG_HEIGHT :: 512, 512
PPU_DEBUG_SCALE :: 2

LCDS_MODE_0_H_BLANK     :: u8(0)
LCDS_MODE_1_V_BLANK     :: u8(1)
LCDS_MODE_2_OAM_SEARCH  :: u8(2)
LCDS_MODE_3_DRAWING     :: u8(3)

OBJECT_ATTRIBUTE_ADDRESS :: 0xFE00

LCDRegisters :: struct {
    control: u8,
    status: u8,
    scy: u8,
    scx: u8,
    ly: u8,
    lyc: u8,
    oam_dma: u8,
    bgp: u8,
    obp0: u8,
    obp1: u8,
    wy: u8,
    wx: u8
}

ObjectAttributeData :: struct {
    pos_y: u8,
    pos_x: u8,
    tile_id: u8,
    flags: u8,
}

OAMBufferData :: struct {
    id: u8,
    drawn: bool,
}

PixelFIFOData :: struct {
    color: u8,
    from_sprite: bool,
}

ppu_lcd_registers := cast(^LCDRegisters)&system_memory[0xFF40]
frame_pixels: [LCD_PIXEL_HEIGHT][LCD_PIXEL_WIDTH]u8
sprite_palette_0 := [4]u8{ 0, 1, 2, 3 }
sprite_palette_1 := [4]u8{ 0, 1, 2, 3 }
background_palette := [4]u8{ 0, 1, 2, 3 }
ppu_scanline_dot: u16
ppu_pixel_buffer: [8]u8
ppu_first_frame_after_lcd_enable := false
ppu_oam_buffer_count :u8= 0
ppu_oam_search_index :u8= 0
ppu_oam_buffer := [10]OAMBufferData {}

ppu_init :: proc() {
    slice.zero(frame_pixels[:])
}

ppu_reset :: proc() {
    ppu_lcd_registers.control = 0x91
    ppu_lcd_registers.status = 0x85
    ppu_lcd_registers.scy = 0
    ppu_lcd_registers.scx = 0
    ppu_lcd_registers.ly = 0
    ppu_lcd_registers.lyc = 0
    ppu_lcd_registers.oam_dma = 0xFF
    ppu_lcd_registers.bgp = 0xFC
    ppu_lcd_registers.obp0 = 0xFF
    ppu_lcd_registers.obp1 = 0xFF
    ppu_lcd_registers.wy = 0
    ppu_lcd_registers.wx = 0
    ppu_scanline_dot = 0
    ppu_first_frame_after_lcd_enable = false
}

@(private="file")
oam_search_tick :: proc() {
    if ppu_scanline_dot % 2 == 0 || ppu_oam_buffer_count == 10 do return
    sprite_height :u8= 16 if lcdc_sprite_size() else 8
    attribute_data_index := ppu_oam_search_index
    sprite := get_object_attribute_data(attribute_data_index)
    pos_y := sprite.pos_y
    ly := ppu_lcd_registers.ly + 16
    if sprite.pos_x > 0 && ly >= pos_y && ly < pos_y + sprite_height {
        ppu_oam_buffer[ppu_oam_buffer_count].id = attribute_data_index
        ppu_oam_buffer[ppu_oam_buffer_count].drawn = false
        ppu_oam_buffer_count += 1
    }
    ppu_oam_search_index += 1
}

ppu_advance_clock :: proc (clocks: u32) {
    if !lcdc_enable_lcd() do return

    for _ in 0..<clocks {
        ppu_mode := lcds_ppu_mode()
        if ppu_mode == LCDS_MODE_2_OAM_SEARCH {
            oam_search_tick()
            if ppu_scanline_dot == 79 {
                ppu_set_lcd_mode(LCDS_MODE_3_DRAWING)
                discard_pixels = ppu_lcd_registers.scx % 8
                ppu_debug_clock_spent_in_mode2[ppu_lcd_registers.ly] = ppu_scanline_dot
            }
        } else if ppu_mode == LCDS_MODE_3_DRAWING {
            fetcher_tick()
            shifter_tick()
            if lcds_ppu_mode() != LCDS_MODE_3_DRAWING {
                ppu_debug_clock_spent_in_mode3[ppu_lcd_registers.ly] = ppu_scanline_dot
            }
        } else if ppu_mode == LCDS_MODE_0_H_BLANK {
            if ppu_first_frame_after_lcd_enable && ppu_lcd_registers.ly == 0 {
                if ppu_scanline_dot == 79 {
                    ppu_set_lcd_mode(LCDS_MODE_3_DRAWING)
                    ppu_debug_clock_spent_in_mode0[ppu_lcd_registers.ly] = ppu_scanline_dot
                } else if ppu_scanline_dot == 451 {
                    ppu_scanline_dot = 0
                    ppu_lcd_registers.ly += 1
                    ppu_check_ly_compare()
                    continue
                }
            }
            if ppu_scanline_dot == 455 {
                ppu_debug_clock_spent_in_mode0[ppu_lcd_registers.ly] = ppu_scanline_dot
                ppu_scanline_dot = 0
                ppu_lcd_registers.ly += 1
                if ppu_lcd_registers.ly == 144 {
                    ppu_set_lcd_mode(LCDS_MODE_1_V_BLANK)
                    interrupt_raise_flag(.VBlank)
                    ppu_check_ly_compare()
                } else {
                    ppu_set_lcd_mode(LCDS_MODE_2_OAM_SEARCH)
                    ppu_check_ly_compare()
                }
                continue
            }
        } else if ppu_mode == LCDS_MODE_1_V_BLANK {
            if ppu_scanline_dot == 455 {
                ppu_debug_clock_spent_in_mode1[ppu_lcd_registers.ly] = ppu_scanline_dot
                ppu_scanline_dot = 0
                ppu_lcd_registers.ly += 1
                ppu_check_ly_compare()
                if ppu_lcd_registers.ly == 154 {
                    ppu_lcd_registers.ly = 0
                    render_frame()
                    render_debug()
                    ppu_set_lcd_mode(LCDS_MODE_2_OAM_SEARCH)
                    ppu_first_frame_after_lcd_enable = false

                    core_on_frame()
                }
                ppu_check_ly_compare()
                continue
            }
        }

        ppu_scanline_dot += 1
    }
}

ppu_check_ly_compare :: proc () {
    if lcdc_enable_lcd() && ppu_lcd_registers.ly == ppu_lcd_registers.lyc {
        change_bit(&ppu_lcd_registers.status, 1, 2)
    } else {
        change_bit(&ppu_lcd_registers.status, 0, 2)
    }
}

ppu_check_stat_signal :: proc() {
    if !lcdc_enable_lcd() do return

    ppu_mode := lcds_ppu_mode()
    if (ppu_lcd_registers.ly == ppu_lcd_registers.lyc && lcds_lyc_equals_ly_interrupt_enable()) ||
        (ppu_mode == LCDS_MODE_2_OAM_SEARCH && lcds_mode_2_stat_interrupt_enable()) ||
        (ppu_mode == LCDS_MODE_0_H_BLANK && lcds_mode_0_stat_interrupt_enable()) ||
        (ppu_mode == LCDS_MODE_1_V_BLANK && lcds_mode_1_stat_interrupt_enable())
    {
        interrupt_raise_flag(.Stat)
    }
}

ppu_on_lyc_write :: proc(value: u8) {
    ppu_lcd_registers.lyc = value
    if lcdc_enable_lcd() {
        ppu_check_ly_compare()
        ppu_check_stat_signal()
    }
}

ppu_set_lcd_mode :: proc (mode: u8) {
    prev_ppu_mode := lcds_ppu_mode()
    curr_ppu_mode := mode & 0b0000_0011
    prev_lcd_status := ppu_lcd_registers.status
    curr_lcd_status := (prev_lcd_status & 0b1111_1100) | curr_ppu_mode
    ppu_lcd_registers.status = curr_lcd_status

    if curr_ppu_mode != prev_ppu_mode {
        ppu_check_stat_signal()
        if curr_ppu_mode == LCDS_MODE_1_V_BLANK {
            fetcher_reset()
        } else if curr_ppu_mode == LCDS_MODE_2_OAM_SEARCH {
            ppu_oam_search_index = 0
            ppu_oam_buffer_count = 0
        } else if curr_ppu_mode == LCDS_MODE_3_DRAWING {
            slice.zero(ppu_pixel_buffer[:])
        }
    }
}

@(private="file")
fetcher_internal_clock: u8

@(private="file")
fetcher_sprite_active: bool

@(private="file")
oam_sprite_fetcher_index: u8

@(private="file")
fetcher_tile_no : u8

@(private="file")
fetcher_window_pixels: bool

@(private="file")
fetcher_internal_x_pos: u8

@(private="file")
fetcher_window_line_counter: u16

@(private="file")
fetcher_tile_data: [2]u8

@(private="file")
pixel_fifo_cursor: u8

@(private="file")
pixel_fifo: [16]PixelFIFOData

@(private="file")
pixel_fifo_occupancy: u8

@(private="file")
fetcher_first_scanline_step: bool

@(private="file")
fetcher_tick :: proc () {
    fetcher_internal_clock += 1
    // Each fetcher step takes 2 clock cycles to execute
    if fetcher_internal_clock == 2 {    // Step 1: fetch tile address
        if fetcher_sprite_active {
        sprite := get_object_attribute_data(ppu_oam_buffer[oam_sprite_fetcher_index].id)
        fetcher_tile_no = sprite.tile_id
        } else {
            if !fetcher_window_pixels || !lcdc_window_enable() {
                tile_map_data := system_memory[0x9C00 if lcdc_bg_tile_map_select() else 0x9800:]
                tile_x_offset := cast(u16)((fetcher_internal_x_pos + (ppu_lcd_registers.scx / 8)) & 0x1F)
                tile_y_offset := (u16(32) * cast(u16)(((ppu_lcd_registers.ly + ppu_lcd_registers.scy) & 0xFF) / 8))
                tile_address := (tile_x_offset + tile_y_offset) & 0x3FF
                fetcher_tile_no = tile_map_data[tile_address]
            } else {
                tile_map_data := system_memory[0x9C00 if lcdc_window_tile_map_select() else 0x9800:]
                tile_x_offset := cast(u16)(fetcher_internal_x_pos)
                tile_y_offset := u16(32) * (fetcher_window_line_counter / 8)
                tile_address := (tile_x_offset + tile_y_offset) & 0x3FF
                fetcher_tile_no = tile_map_data[tile_address]
            }
        }
    } else if fetcher_internal_clock == 4 || fetcher_internal_clock == 6 {
        high_byte := fetcher_internal_clock == 6
        if fetcher_sprite_active {
            sprite := get_object_attribute_data(ppu_oam_buffer[oam_sprite_fetcher_index].id)
            tile_data := system_memory[0x8000:]
            tile_data_offset := cast(u16)fetcher_tile_no * 16
            flip_y := check_bit(sprite.flags, 6)
            flip_offset := u8(30) if lcdc_sprite_size() else 14
            vertical_offset := u16(2) * cast(u16)(ppu_lcd_registers.ly - (sprite.pos_y - 16))
            offset := cast(u16)flip_offset - vertical_offset if flip_y else vertical_offset
            pixel_data_address := tile_data_offset + offset + (1 if high_byte else 0)
            fetcher_tile_data[1 if high_byte else 0] = tile_data[pixel_data_address]
        } else {
            tile_data := system_memory[:]
            tile_data_offset := cast(u16)(0x8000 + int(fetcher_tile_no) * 16)
            if !lcdc_tile_data_select() {
                tile_data_offset = cast(u16)(0x9000 + int(i8(fetcher_tile_no)) * 16)
            }
            if !fetcher_window_pixels {
                offset := cast(u16)(u8(2) * ((ppu_lcd_registers.ly + ppu_lcd_registers.scy) % 8))
                pixel_data_address := tile_data_offset + offset + (1 if high_byte else 0)
                fetcher_tile_data[1 if high_byte else 0] = tile_data[pixel_data_address]
            } else {
                offset := u16(2) * ((fetcher_window_line_counter) % 8)
                pixel_data_address := tile_data_offset + offset + (1 if high_byte else 0)
                fetcher_tile_data[1 if high_byte else 0] = tile_data[pixel_data_address]
            }
        }
    }

    if fetcher_internal_clock >= 6 {
        if fetcher_sprite_active {
            sprite := get_object_attribute_data(ppu_oam_buffer[oam_sprite_fetcher_index].id)
            sprite_use_palette1 := check_bit(sprite.flags, 4)
            sprite_flip_x := check_bit(sprite.flags, 5)
            sprite_bg_priority := check_bit(sprite.flags, 7)
            for column in u8(0)..<8 {
                right_bit := (fetcher_tile_data[0] & (0b1000_0000 >> column)) >> (7 - column)
                left_bit := (fetcher_tile_data[1] & (0b1000_0000 >> column)) >> (7 - column)
                pixel_value_sprite := ((left_bit << 1) | (right_bit))
                index := (pixel_fifo_cursor + ((7 - column) if sprite_flip_x else column)) % 16
                if pixel_value_sprite > 0 && !pixel_fifo[index].from_sprite &&
                    !(sprite_bg_priority && pixel_fifo[index].color > 0)
                {
                    paletted_pixel_value_sprite :=
                        sprite_palette_1[pixel_value_sprite] if sprite_use_palette1 else sprite_palette_0[pixel_value_sprite]
                    pixel_fifo[index].color = paletted_pixel_value_sprite
                    pixel_fifo[index].from_sprite = true
                }
            }

            ppu_oam_buffer[oam_sprite_fetcher_index].drawn = true
            fetcher_internal_clock = 0
            fetcher_sprite_active =  false
        } else if pixel_fifo_occupancy <= 8 {
            for column in u8(0)..<8 {
                index := (pixel_fifo_cursor + pixel_fifo_occupancy) % 16
                right_bit := (fetcher_tile_data[0] & (0b1000_0000 >> column)) >> (7 - column)
                left_bit := (fetcher_tile_data[1] & (0b1000_0000 >> column)) >> (7 - column)
                pixel_value_bg := ((left_bit << 1) | right_bit)
                pixel_fifo[index].color = pixel_value_bg if lcdc_bg_window_enabled() else 0
                pixel_fifo[index].from_sprite = false
                pixel_fifo_occupancy += 1
            }
            fetcher_internal_clock = 0
            if !fetcher_first_scanline_step {
                fetcher_internal_x_pos += 1
            } else {
                fetcher_first_scanline_step = false
            }
        }
    }

}

@(private="file")
shifter_pixel_x: i16

@(private="file")
discard_pixels: u8

@(private="file")
shifter_tick :: proc () {
    if fetcher_sprite_active do return
    if pixel_fifo_occupancy <= 8 do return

    if lcdc_sprite_enabled() && ppu_oam_buffer_count > 0 {
        for i in u8(0)..<ppu_oam_buffer_count {
            if ppu_oam_buffer[i].drawn do continue
            sprite := get_object_attribute_data(ppu_oam_buffer[i].id)
            if cast(i16)sprite.pos_x <= shifter_pixel_x + 8 &&
                cast(i16)sprite.pos_x > shifter_pixel_x
            {
                oam_sprite_fetcher_index = i
                fetcher_internal_clock = 0
                fetcher_sprite_active = true
                return
            }
        }
    }

    if discard_pixels > 0 && !fetcher_window_pixels {
        discard_pixels -= 1
        pixel_fifo_occupancy -= 1
        pixel_fifo_cursor += 1
        return
    }

    if shifter_pixel_x >= 0 {
        pixel_value := pixel_fifo[pixel_fifo_cursor].color
        if pixel_fifo[pixel_fifo_cursor].from_sprite {
            frame_pixels[ppu_lcd_registers.ly][shifter_pixel_x] = pixel_value
        } else {
            paletted_pixel_value_bg := background_palette[pixel_value]
            frame_pixels[ppu_lcd_registers.ly][shifter_pixel_x] = paletted_pixel_value_bg
        }
    }

    shifter_pixel_x += 1
    pixel_fifo_occupancy -= 1
    pixel_fifo_cursor = (pixel_fifo_cursor + 1) % 16
    if lcdc_window_enable() &&
        ppu_lcd_registers.wy == ppu_lcd_registers.ly &&
        shifter_pixel_x >= cast(i16)ppu_lcd_registers.wx - 7 &&
        !fetcher_window_pixels
    {
        fetcher_reset()
        fetcher_window_pixels = true
    }

    if shifter_pixel_x == 160 { // reached H-blank
        shifter_pixel_x = -8
        pixel_fifo_cursor = 0
        pixel_fifo_occupancy = 0
        fetcher_internal_x_pos = 0
        fetcher_internal_clock = 0
        fetcher_first_scanline_step = true
        if fetcher_window_pixels {
            fetcher_window_line_counter += 1
        }
        ppu_set_lcd_mode(LCDS_MODE_0_H_BLANK)
    }
}

@(private="file")
fetcher_reset :: proc() {
    fetcher_sprite_active = false
    fetcher_internal_clock = 0
    fetcher_internal_x_pos = 0
    fetcher_window_pixels = false
    fetcher_window_line_counter = 0
    fetcher_tile_no = 0
    slice.zero(fetcher_tile_data[:])
    slice.zero(pixel_fifo[:])
    pixel_fifo_occupancy = 0
    pixel_fifo_cursor = 0
}

@(private="file")
get_object_attribute_data :: proc(id: u8) -> ^ObjectAttributeData {
    data := cast([^]ObjectAttributeData)&system_memory[OBJECT_ATTRIBUTE_ADDRESS]
    return &data[id]
}

ppu_on_lcd_control_write :: proc(value: u8) {
    prev_lcd_enabled := lcdc_enable_lcd()
    ppu_lcd_registers.control = value
    curr_lcd_enabled := lcdc_enable_lcd()
    if prev_lcd_enabled != curr_lcd_enabled {
        ppu_scanline_dot = 0
        ppu_lcd_registers.ly = 0
        ppu_set_lcd_mode(LCDS_MODE_0_H_BLANK)

        if curr_lcd_enabled {
            ppu_first_frame_after_lcd_enable = true
        }

        ppu_check_stat_signal()
    }
}

ppu_on_lcd_status_write :: proc(value: u8) {
    prev_value := ppu_lcd_registers.status
    curr_value := (prev_value & 0b1000_0111) | (value & 0b0111_1000)
    ppu_lcd_registers.status = curr_value
    ppu_check_stat_signal()

}

@(private = "file")
extract_palette :: proc (addr: u16, palette: []u8) {
    pal := system_memory[addr]
    palette[0] = (pal & 0b0000_0011) >> 0
    palette[1] = (pal & 0b0000_1100) >> 2
    palette[2] = (pal & 0b0011_0000) >> 4
    palette[3] = (pal & 0b1100_0000) >> 6
}

ppu_on_palette_write :: proc(addr: u16) {
    if addr == 0xFF47 do extract_palette(addr, background_palette[:])
    if addr == 0xFF48 do extract_palette(addr, sprite_palette_0[:])
    if addr == 0xFF49 do extract_palette(addr, sprite_palette_1[:])
}

PPU_LCD_COLOR_LIT :: sdl.Color{223, 230, 179, 255}
PPU_GB_COLOR := [4]sdl.Color {
    {185, 200,  90, 255},
    {131, 145,   0, 255},
    { 74,  82,   4, 255},
    { 40,  44,   4, 255},
}

PPU_DEBUG_COLOR_GRAY := [4]sdl.Color{
    {200, 200, 200, 255},
    {145, 145, 145, 255},
    { 82,  82,  82, 255},
    { 44,  44,  44, 255},
}

PPU_DEBUG_COLOR_SPRITE := [4]sdl.Color{
    {200,  90,  90, 255},
    {145,  80,   0, 255},
    { 82,  40,   0, 255},
    { 44,   0,   0, 255},
}

PPU_DEBUG_COLOR_WINDOW := [4]sdl.Color{
    { 90,  90, 200, 255},
    {  0,  80, 145, 255},
    {  0,  40,  82, 255},
    {  0,   0,  44, 255},
}

render_frame :: proc() {
    sdl.SetRenderDrawColor(
        render_gfx_ctx.renderer,
        PPU_LCD_COLOR_LIT.r,
        PPU_LCD_COLOR_LIT.g,
        PPU_LCD_COLOR_LIT.b,
        PPU_LCD_COLOR_LIT.a,
    )

    pixels, pitch, lock_ok := lock_sdl_texture(render_gfx_ctx.texture)

    if !lcdc_enable_lcd() || ppu_first_frame_after_lcd_enable || !lock_ok {
        sdl.RenderClear(render_gfx_ctx.renderer)
        sdl.RenderPresent(render_gfx_ctx.renderer)
        return
    }

    for y in u16(0)..<LCD_PIXEL_HEIGHT {
        for x in u16(0)..<LCD_PIXEL_WIDTH {
            color_index := frame_pixels[y][x]
            color := PPU_GB_COLOR[color_index]
            base := int(y) * int(pitch) + int(x) * 4
            target := pixels[base:base+4]
            target[0] = color.a
            target[1] = color.b
            target[2] = color.g
            target[3] = color.r
        }
    }
    sdl.UnlockTexture(render_gfx_ctx.texture)

    src_rect := sdl.FRect{0, 0, cast(f32)LCD_PIXEL_WIDTH, cast(f32)LCD_PIXEL_HEIGHT}
    ok := sdl.RenderTexture(render_gfx_ctx.renderer, render_gfx_ctx.texture, &src_rect, nil)
    assert(ok)
    sdl.RenderPresent(render_gfx_ctx.renderer)

    slice.zero(frame_pixels[:])
}

render_debug :: proc() {
    pixels, pitch, lock_ok := lock_sdl_texture(debug_gfx_ctx.texture)

    if !lock_ok {
        sdl.RenderClear(debug_gfx_ctx.renderer)
    } else {
        render_debug_vram(pixels, pitch, 256, 0)
        render_debug_background(pixels, pitch, 0, 0)

        // render_debug_sprites(pixels, pitch, true, 0, 0)         // position over BG
        render_debug_sprites(pixels, pitch, false, 0, 0)      // sprite pixels
        render_debug_window(pixels, pitch, 0, 0)
        render_debug_viewport(pixels, pitch, 0, 0)
        render_debug_timings(pixels, cast(int)pitch)

        sdl.UnlockTexture(debug_gfx_ctx.texture)

        src_rect := sdl.FRect{0, 0, 512, 512}
        sdl.RenderTexture(debug_gfx_ctx.renderer, debug_gfx_ctx.texture, &src_rect, nil)
    }

    sdl.RenderPresent(debug_gfx_ctx.renderer)
}

@(private="file")
render_debug_vram :: proc(pixels: []u8, pitch: i32, offset_x, offset_y: int) {
    tile_data := system_memory[0x8000:]
    for tile_id in u16(0)..<384 {
        tile_x := tile_id % 16
        tile_y := tile_id / 16
        tile_data_offset := tile_id * 16
        for row in u16(0)..<8 {
            screen_y := (tile_y * 8) + row

            pixel_data_offset := (row * 2) + tile_data_offset
            pixel_data := tile_data[pixel_data_offset:pixel_data_offset+2]

            pixel_buffer: [8]u8
            pixel_buffer[0] = ((pixel_data[0] & 0b1000_0000) >> 7) | ((pixel_data[1] & 0b1000_0000) >> 6)
            pixel_buffer[1] = ((pixel_data[0] & 0b0100_0000) >> 6) | ((pixel_data[1] & 0b0100_0000) >> 5)
            pixel_buffer[2] = ((pixel_data[0] & 0b0010_0000) >> 5) | ((pixel_data[1] & 0b0010_0000) >> 4)
            pixel_buffer[3] = ((pixel_data[0] & 0b0001_0000) >> 4) | ((pixel_data[1] & 0b0001_0000) >> 3)
            pixel_buffer[4] = ((pixel_data[0] & 0b0000_1000) >> 3) | ((pixel_data[1] & 0b0000_1000) >> 2)
            pixel_buffer[5] = ((pixel_data[0] & 0b0000_0100) >> 2) | ((pixel_data[1] & 0b0000_0100) >> 1)
            pixel_buffer[6] = ((pixel_data[0] & 0b0000_0010) >> 1) | ((pixel_data[1] & 0b0000_0010) >> 0)
            pixel_buffer[7] = ((pixel_data[0] & 0b0000_0001) >> 0) | ((pixel_data[1] & 0b0000_0001) << 1)

            for column in 0..<8 {
                screen_x := int(tile_x * 8) + column
                color := PPU_DEBUG_COLOR_GRAY[pixel_buffer[column]]
                pixel_offset := (int(screen_y) + offset_y) * int(pitch) + (int(screen_x) + offset_x) * 4
                pixels[pixel_offset + 0] = color.a
                pixels[pixel_offset + 1] = color.b
                pixels[pixel_offset + 2] = color.g
                pixels[pixel_offset + 3] = color.r
            }
        }
    }
}

@(private="file")
render_debug_background :: proc(pixels: []u8, pitch: i32, offset_x, offset_y: int) {
    tile_data := system_memory[0x8000:]
    tile_map_data := system_memory[0x9C00 if lcdc_bg_tile_map_select() else 0x9800:]
    for tile_y in 0..<32 {
        for tile_x in 0..<32 {
            tile_index_u := tile_map_data[(tile_y * 32) + tile_x]
            tile_index_s := cast(i8)tile_index_u
            tile_index := cast(int)tile_index_u if lcdc_tile_data_select() else cast(int)tile_index_s
            tile_data_offset := tile_index * 16 + (0x1000 if !lcdc_tile_data_select() else 0)
            for row in 0..<8 {
                screen_y := (tile_y * 8) + row
                pixel_data_offset := tile_data_offset + (row * 2)
                pixel_data := tile_data[pixel_data_offset:pixel_data_offset+2]

                pixel_buffer: [8]u8
                pixel_buffer[0] = ((pixel_data[0] & 0b1000_0000) >> 7) | ((pixel_data[1] & 0b1000_0000) >> 6)
                pixel_buffer[1] = ((pixel_data[0] & 0b0100_0000) >> 6) | ((pixel_data[1] & 0b0100_0000) >> 5)
                pixel_buffer[2] = ((pixel_data[0] & 0b0010_0000) >> 5) | ((pixel_data[1] & 0b0010_0000) >> 4)
                pixel_buffer[3] = ((pixel_data[0] & 0b0001_0000) >> 4) | ((pixel_data[1] & 0b0001_0000) >> 3)
                pixel_buffer[4] = ((pixel_data[0] & 0b0000_1000) >> 3) | ((pixel_data[1] & 0b0000_1000) >> 2)
                pixel_buffer[5] = ((pixel_data[0] & 0b0000_0100) >> 2) | ((pixel_data[1] & 0b0000_0100) >> 1)
                pixel_buffer[6] = ((pixel_data[0] & 0b0000_0010) >> 1) | ((pixel_data[1] & 0b0000_0010) >> 0)
                pixel_buffer[7] = ((pixel_data[0] & 0b0000_0001) >> 0) | ((pixel_data[1] & 0b0000_0001) << 1)

                for column in 0..<8 {
                    screen_x := (tile_x * 8) + column
                    color := PPU_DEBUG_COLOR_GRAY[pixel_buffer[column]]

                    pixel_offset := (int(screen_y) + offset_y) * int(pitch) + (int(screen_x) + offset_x) * 4
                    pixels[pixel_offset + 0] = color.a
                    pixels[pixel_offset + 1] = color.b
                    pixels[pixel_offset + 2] = color.g
                    pixels[pixel_offset + 3] = color.r
                }
            }
        }
    }
}

@(private="file")
draw_sprite_position_only := false

@(private="file")
render_debug_sprites :: proc(pixels: []u8, pitch: i32, draw_sprite_position_only: bool, offset_x, offset_y: int) {
    double_height_sprites := check_bit(ppu_lcd_registers.control, 2)
    sprite_height := 16 if double_height_sprites else 8
    scx := cast(int)ppu_lcd_registers.scx
    scy := cast(int)ppu_lcd_registers.scy

    if draw_sprite_position_only {
        for index in 0..<40 {
            sprite := get_object_attribute_data(cast(u8)index)
            off_screen := (sprite.pos_y < 8 || sprite.pos_y >= 160) || (sprite.pos_x == 0 || sprite.pos_x >= 168)
            if off_screen do continue

            pos_y := (scy + cast(int)sprite.pos_y - 16)
            pos_x := (scx + cast(int)sprite.pos_x -  8)
            for y in 0..<sprite_height {
                for x in 0..<8 {
                    pixel_y := (pos_y + y)
                    pixel_x := (pos_x + x)

                    base := pixels[(pixel_y + offset_y) * cast(int)pitch + (pixel_x + offset_x) * 4:]
                    base [1] = 0
                    base [2] = 0
                    base [3] = 255
                }
            }
        }
    } else {
        tile_data := system_memory[0x8000:]
        for index in 0..<40 {
            sprite := get_object_attribute_data(cast(u8)index)
            pos_y := (scy + cast(int)sprite.pos_y - 16) % 256
            pos_x := (scx + cast(int)sprite.pos_x -  8) % 256

            sprite_flip_x := check_bit(sprite.flags, 5)
            sprite_flip_y := check_bit(sprite.flags, 6)

            sprite_tile_offset := cast(int)sprite.tile_id * 16

            for column in 0..<sprite_height {
                pixel_data_offset := ((column * 2) if !sprite_flip_y else ((sprite_height-column)*2)) + sprite_tile_offset
                pixel_data := tile_data[pixel_data_offset:pixel_data_offset + 2]

                pixel_buffer: [8]u8
                pixel_buffer[0] = ((pixel_data[0] & 0b1000_0000) >> 7) | ((pixel_data[1] & 0b1000_0000) >> 6)
                pixel_buffer[1] = ((pixel_data[0] & 0b0100_0000) >> 6) | ((pixel_data[1] & 0b0100_0000) >> 5)
                pixel_buffer[2] = ((pixel_data[0] & 0b0010_0000) >> 5) | ((pixel_data[1] & 0b0010_0000) >> 4)
                pixel_buffer[3] = ((pixel_data[0] & 0b0001_0000) >> 4) | ((pixel_data[1] & 0b0001_0000) >> 3)
                pixel_buffer[4] = ((pixel_data[0] & 0b0000_1000) >> 3) | ((pixel_data[1] & 0b0000_1000) >> 2)
                pixel_buffer[5] = ((pixel_data[0] & 0b0000_0100) >> 2) | ((pixel_data[1] & 0b0000_0100) >> 1)
                pixel_buffer[6] = ((pixel_data[0] & 0b0000_0010) >> 1) | ((pixel_data[1] & 0b0000_0010) >> 0)
                pixel_buffer[7] = ((pixel_data[0] & 0b0000_0001) >> 0) | ((pixel_data[1] & 0b0000_0001) << 1)

                screen_y := pos_y + column
                for row in 0..<8 {
                    screen_x := pos_x + row
                    if screen_x < 0 || screen_y < 0 || screen_x >= 512 || screen_y >= 512 do continue

                    color := PPU_DEBUG_COLOR_SPRITE[pixel_buffer[row if !sprite_flip_x else 7 - row]]

                    pixel_offset := (int(screen_y) + offset_y) * int(pitch) + (int(screen_x) + offset_x) * 4
                    pixels[pixel_offset + 0] = color.a
                    pixels[pixel_offset + 1] = color.b
                    pixels[pixel_offset + 2] = color.g
                    pixels[pixel_offset + 3] = color.r
                }
            }
        }

    }
}

@(private="file")
render_debug_window :: proc(pixels: []u8, pitch: i32, offset_x, offset_y: int) {
    if !lcdc_window_enable() do return

    wx := cast(int)ppu_lcd_registers.wx
    wy := cast(int)ppu_lcd_registers.wy
    if wx >= 166 || wy > 143 do return

    draw_location_only :: false

    if draw_location_only {
        scx := cast(int)ppu_lcd_registers.scx
        scy := cast(int)ppu_lcd_registers.scy
        for x in wx - 7..<LCD_PIXEL_WIDTH {
            for y in wy..< LCD_PIXEL_HEIGHT {
                xpos := scx + x
                ypos := scy + y
                pixel_offset := (ypos + offset_y) * cast(int)pitch + (xpos + offset_x) * 4
                pixels[pixel_offset + 1] = 255
            }
        }
    } else {
        tile_map_data_window := system_memory[0x9C00 if lcdc_window_tile_map_select() else 0x9800:]
        tile_data := system_memory[0x8000:]

        scx := cast(int)ppu_lcd_registers.scx
        scy := cast(int)ppu_lcd_registers.scy

        tiles_x := (LCD_PIXEL_WIDTH - (wx - 7)) / 8
        tiles_y := (LCD_PIXEL_HEIGHT - (wy - 7)) / 8
        for tile_x in 0..<tiles_x {
            for tile_y in 0..<tiles_y {
                tile_index_u := tile_map_data_window[(tile_y * 32) + tile_x]
                tile_index_s := cast(i8)tile_index_u
                tile_index := cast(int)tile_index_u if lcdc_tile_data_select() else cast(int)tile_index_s
                tile_data_offset := tile_index * 16 + (0x1000 if !lcdc_tile_data_select() else 0)
                for row in 0..<8 {
                    pixel_data_offset := (tile_data_offset) + row * 2
                    pixel_data := tile_data[pixel_data_offset:]

                    pixel_buffer: [8]u8
                    pixel_buffer[0] = ((pixel_data[0] & 0b1000_0000) >> 7) | ((pixel_data[1] & 0b1000_0000) >> 6)
                    pixel_buffer[1] = ((pixel_data[0] & 0b0100_0000) >> 6) | ((pixel_data[1] & 0b0100_0000) >> 5)
                    pixel_buffer[2] = ((pixel_data[0] & 0b0010_0000) >> 5) | ((pixel_data[1] & 0b0010_0000) >> 4)
                    pixel_buffer[3] = ((pixel_data[0] & 0b0001_0000) >> 4) | ((pixel_data[1] & 0b0001_0000) >> 3)
                    pixel_buffer[4] = ((pixel_data[0] & 0b0000_1000) >> 3) | ((pixel_data[1] & 0b0000_1000) >> 2)
                    pixel_buffer[5] = ((pixel_data[0] & 0b0000_0100) >> 2) | ((pixel_data[1] & 0b0000_0100) >> 1)
                    pixel_buffer[6] = ((pixel_data[0] & 0b0000_0010) >> 1) | ((pixel_data[1] & 0b0000_0010) >> 0)
                    pixel_buffer[7] = ((pixel_data[0] & 0b0000_0001) >> 0) | ((pixel_data[1] & 0b0000_0001) << 1)

                    screen_y := (scy + wy + tile_y * 8 + row) % 256
                    for column in 0..<8 {
                        screen_x := (scx + wx - 7 + tile_x * 8 + column) % 256

                        if screen_x < 0 || screen_y <0 || screen_x >= 512 || screen_y >= 512 do continue

                        color := PPU_DEBUG_COLOR_WINDOW[pixel_buffer[column]]

                        pixel_offset := (int(screen_y) + offset_y) * int(pitch) + (int(screen_x) + offset_x) * 4
                        pixels[pixel_offset + 0] = color.a
                        pixels[pixel_offset + 1] = color.b
                        pixels[pixel_offset + 2] = color.g
                        pixels[pixel_offset + 3] = color.r
                    }
                }
            }
        }
    }


}

@(private="file")
render_debug_viewport :: proc(pixels: []u8, pitch: i32, offset_x, offset_y: int) {
    scx := cast(int)ppu_lcd_registers.scx
    scy := cast(int)ppu_lcd_registers.scy
    for x in 0..<LCD_PIXEL_WIDTH {
        wrap_x := (scx + x) % 256
        wrap_y := (scy + 144) % 256
        pixels[4 * ((scy * 512) + wrap_x):][3] = 255
        pixels[4 * ((wrap_y * 512) + wrap_x):][3] = 255
    }
    for y in 0..<LCD_PIXEL_HEIGHT {
        wrap_x := (scx + 160) % 256
        wrap_y := (scy + y) % 256
        pixels[4 * ((wrap_y * 512) + scx):][3] = 255
        pixels[4 * ((wrap_y * 512) + wrap_x):][3] = 255
    }
}

@(private="file")
ppu_debug_clock_spent_in_mode0: [154]u16
ppu_debug_clock_spent_in_mode1: [154]u16
ppu_debug_clock_spent_in_mode2: [154]u16
ppu_debug_clock_spent_in_mode3: [154]u16

@(private="file")
render_debug_timings :: proc(pixels: []u8, pitch: int) {
    for row in 0..<154 {
        screen_y := row + 256
        start := u16(0)
        end := ppu_debug_clock_spent_in_mode2[row]
        for column in start..<end {
            color := sdl.Color{255, 255, 0, 255} // OAM search = yellow
            base := pixels[(screen_y * pitch) + cast(int)column * 4:]
            base[0] = color.a; base[1] = color.b; base[2] = color.g; base[3] = color.r
        }
        start = ppu_debug_clock_spent_in_mode2[row]
        end = ppu_debug_clock_spent_in_mode3[row]
        for column in start..<end {
            color := sdl.Color{0, 255, 0, 255} // Draw = green
            base := pixels[(screen_y * pitch) + cast(int)column * 4:]
            base[0] = color.a; base[1] = color.b; base[2] = color.g; base[3] = color.r
        }
        start = ppu_debug_clock_spent_in_mode3[row]
        end = ppu_debug_clock_spent_in_mode0[row]
        for column in start..<end {
            color := sdl.Color{128, 128, 128, 255} // HBlank = gray
            base := pixels[(screen_y * pitch) + cast(int)column * 4:]
            base[0] = color.a; base[1] = color.b; base[2] = color.g; base[3] = color.r
        }
        start = ppu_debug_clock_spent_in_mode0[row]
        end = ppu_debug_clock_spent_in_mode1[row]
        for column in start..<end {
            color := sdl.Color{0, 255, 255, 255} // VBlank = teal
            base := pixels[(screen_y * pitch) + cast(int)column * 4:]
            base[0] = color.a; base[1] = color.b; base[2] = color.g; base[3] = color.r
        }
    }
}

@(private="file")
lock_sdl_texture :: proc(texture: ^sdl.Texture) -> (pixels: []u8, pitch: i32, ok: bool) {
    pixel_data: [^]u8

    if !sdl.LockTexture(texture, nil, auto_cast &pixel_data, &pitch) do return
    defer if !ok do sdl.UnlockTexture(texture)

    w, h: f32
    if !sdl.GetTextureSize(texture, &w, &h) do return

    return slice.from_ptr(pixel_data, int(pitch) * int(h)), pitch, true
}

// LCD CONTROL FLAGS
lcdc_enable_lcd             :: #force_inline proc () -> bool { return check_bit(ppu_lcd_registers.control, 7) }
lcdc_window_tile_map_select :: #force_inline proc () -> bool { return check_bit(ppu_lcd_registers.control, 6) }
lcdc_window_enable          :: #force_inline proc () -> bool { return check_bit(ppu_lcd_registers.control, 5) }
lcdc_tile_data_select       :: #force_inline proc () -> bool { return check_bit(ppu_lcd_registers.control, 4) }
lcdc_bg_tile_map_select     :: #force_inline proc () -> bool { return check_bit(ppu_lcd_registers.control, 3) }
lcdc_sprite_size            :: #force_inline proc () -> bool { return check_bit(ppu_lcd_registers.control, 2) }
lcdc_sprite_enabled         :: #force_inline proc () -> bool { return check_bit(ppu_lcd_registers.control, 1) }
lcdc_bg_window_enabled      :: #force_inline proc () -> bool { return check_bit(ppu_lcd_registers.control, 0) }

// LCD STATUS FLAGS
lcds_lyc_equals_ly_interrupt_enable :: #force_inline proc () -> bool { return check_bit(ppu_lcd_registers.status, 6) }
lcds_mode_2_stat_interrupt_enable   :: #force_inline proc () -> bool { return check_bit(ppu_lcd_registers.status, 5) }
lcds_mode_1_stat_interrupt_enable   :: #force_inline proc () -> bool { return check_bit(ppu_lcd_registers.status, 4) }
lcds_mode_0_stat_interrupt_enable   :: #force_inline proc () -> bool { return check_bit(ppu_lcd_registers.status, 3) }
lcds_coincidence_flag               :: #force_inline proc () -> bool { return check_bit(ppu_lcd_registers.status, 2) }
lcds_ppu_mode                       :: #force_inline proc () -> u8   { return ppu_lcd_registers.status & 0b0000_00011 }

