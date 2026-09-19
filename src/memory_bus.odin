package odin_gb

import "core:fmt"

MEMORY_SIZE :: 64 * 1024

system_memory: [MEMORY_SIZE]u8
eram: [1000]u8

ADDR_IO_IF :: 0xFF0F    // Interrupt flag
ADDR_IO_IE :: 0xFFFF    // Interrupt enable

@(private="file")
rom_bank_number := u16(0)

@(private="file")
ram_bank_number := u16(0)

@(private="file")
ram_enabled := false

@(private="file")
rom_ram_mode_select := false

memory_bus_read :: proc (addr: u16) -> u8 {

    if addr >= 0x0000 && addr <= 0x3FFF {   // ROM Bank 0
        return cartridge_data[addr]
    }

    cart_info := cart_data_types[cartridge_header.type]

    if addr >= 0x4000 && addr <= 0x7FFF {   // ROM Bank 1-NN
        if cart_info.type == .NO_MBC {
            return cartridge_data[addr]
        } else if cart_info.type == .MBC1 {
            ROM_BANK_SIZE := u16(0x4000)
            rom_bank := rom_bank_number if rom_bank_number > 0 else 1
            offset := ROM_BANK_SIZE * (rom_bank - 1)
            return cartridge_data[offset + addr]
        }
    }
    if addr >= 0x8000 && addr <= 0x9FFF {   // VRAM
        return system_memory[addr]
    }
    if addr >= 0xA000 && addr <= 0xBFFF {   // External RAM
        if cart_info.type == .NO_MBC {
            eram_addr := addr - 0xA000
            return eram[eram_addr]
        } else if cart_info.type == .MBC1 {
            bank_offset := rom_bank_number * 0x2000
            eram_address := (addr - 0xA000) + bank_offset
            return eram[eram_address]
        }
    }
    if addr >= 0xC000 && addr <= 0xCFFF {   // Work RAM 1
        return system_memory[addr]
    }
    if addr >= 0xD000 && addr <= 0xDFFF {   // Work RAM 2
        return system_memory[addr]
    }
    if addr >= 0xE000 && addr <= 0xFDFF {   // Echo RAM (mirrors C000-DDFF)
        return system_memory[addr - 0x2000]
    }
    if addr >= 0xFE00 && addr <= 0xFE9F {   // Object attribute memory (OEM)
        return system_memory[addr]
    }
    if addr >= 0xFFA0 && addr <= 0xFEFF {   // Unused memory
        // @TODO: return 0xFF id PPU is in mode 3
        return 0x00
    }
    if addr >= 0xFF00 && addr <= 0xFF7F {   // I/0
        // Only return for known DMG I/O ranges. Otherwise, return 0xFF
        if (addr == 0xFF00) ||
            (addr >= 0xFF01 && addr <= 0xFF02) ||
            (addr >= 0xFF04 && addr <= 0xFF07) ||
            (addr == 0xFF0F) ||
            (addr >= 0xFF10 && addr <= 0xFF26) ||
            (addr >= 0xFF30 && addr <= 0xFF3F) ||
            (addr >= 0xFF40 && addr <= 0xFF4B) ||
            (addr == 0xFF46) ||
            (addr == 0xFF50)
        {
            return system_memory[addr]
        }
        return 0xFF
    }
    if addr >= 0xFF80 && addr <= 0xFFFE {   // High RAM
        return system_memory[addr]
    }
    if addr >= 0xFFFF {                     // Interrupt enable flags IE
        return system_memory[addr]
    }
    unreachable()
}

memory_bus_write :: proc (addr: u16, value: u8) {
    cart_info := cart_data_types[cartridge_header.type]
    if cart_info.type == .MBC1 {
        if addr >= 0x0000 && addr <= 0x1FFF {
            ram_enabled = (value & 0xF0) == 0x0A
        }
        if addr >= 0x2000 && addr <= 0x3FFF {
            rom_bank_number = cast(u16)(value & 0b00011111)
            rom_size := u16(32 * (1 << cartridge_header.rom_size))
            number_of_rom_banks := rom_size / 16
            rom_bank_number = rom_bank_number % number_of_rom_banks
        }
        if addr >= 0x4000 && addr <= 0x5FFF {
            if rom_ram_mode_select {
                ram_bank_number = cast(u16)(value & 0b0000_0011)
            } else {
                rom_bank_number = (rom_bank_number & 0b0001_1111) | cast(u16)((value & 0b0000_0011) << 5)
            }
        }
        if addr >= 0x6000 && addr <= 0x7FFF {
            rom_ram_mode_select = (value & 1) != 0
        }
    }

    if addr >= 0x8000 && addr <= 0x9FFF {           // VRAM
        system_memory[addr] = value
    } else if addr >= 0xA000 && addr <= 0xBFFF {    // External RAM
        if cart_info.type == .NO_MBC {
            eram[addr - 0xA000] = value
        } else if cart_info.type == .MBC1 {
            RAM_BANK_SIZE :: u16(0x2000)
            offset := RAM_BANK_SIZE * ram_bank_number
            eram_addr := offset + (addr - 0xA000)
            eram[eram_addr] = value
        }
    } else if addr >= 0xC000 && addr <= 0xCFFF {    // Work RAM 1
        system_memory[addr] = value
    } else if addr >= 0xD000 && addr <= 0xDFFF {    // Work RAM 2
        system_memory[addr] = value
    } else if addr >= 0xE000 && addr <= 0xFDFF {    // Echo RAM (mirrors C000-DDFF)
        system_memory[addr - 0x2000] = value
    } else if addr >= 0xFE00 && addr <= 0xFE9F {    // Object attribute memory (OEM)
        // @TODO: if PPU is mode 2 or 3 the CPU cannot access OEM
        system_memory[addr] = value
    } else if addr >= 0xFFA0 && addr <= 0xFEFF {    // Unused memory
        // all writes are ignored
    } else if addr >= 0xFF00 && addr <= 0xFF7F {    // I/0
        if addr == 0xFF02 && value == 0x81 {    // Blargg tests serial output
            c := rune(system_memory[0xFF01])
            fmt.printf("{}", c)
        } else if addr == 0xFF04 {              // Timer DIV
            timer_on_div_write(value)
        } else if addr == 0xFF07 {              // Timer control
            system_memory[addr] = value & 0b0000_0111
        } else if addr == 0xFF0F {              // Interrupt flag
            interrupt_flag_write(value)
        } else if addr == 0xFF46 {              // OAM DMA
            source_addr := cast(u16)value * 0x100
            dest := u16(0xFE00)
            for i in 0..<160 {
                // @TODO: This takes a number of cycles.Need to advance with
                // the core clock
                system_memory[dest + cast(u16)i] = memory_bus_read(source_addr + cast(u16)i)
            }
        }
    } else if addr >= 0xFF80 && addr <= 0xFFFE {    // High RAM
        system_memory[addr] = value
    } else if addr >= 0xFFFF {                      // Interrupt enable flags IE
        system_memory[addr] = value
    }

    system_memory[addr] = value
}
