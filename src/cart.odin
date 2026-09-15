package odin_gb

import "core:os"
import "core:log"
import "core:fmt"

cart_data: [1024 * 1024]u8

CartHeader :: struct {
    entry_point            : [4]u8,
    nintendo_logo          : [48]u8,
    title                  : [15]u8,
    cgb_flag               : u8,
    new_licensee_code      : [2]u8,
    sgb_flag               : u8,
    cartridge_type         : u8,
    rom_size               : u8,
    ram_size               : u8,
    destination_code       : u8,
    old_licensee_code      : u8,
    mask_rom_version_number: u8,
    header_checksum        : u8,
    global_checksum_hi     : u8,
    global_checksum_lo     : u8,
}

cart_header: ^CartHeader

cart_open_file :: proc () -> (ok: bool) {
    assert(false, "Need to implement the file picker")
    return true
}

cart_print_info :: proc () {
    if cart_header != nil {
        fmt.printfln(
            "Entry Point: {:02X}{:02X}{:02X}{:02X}",
            cart_header.entry_point[0],
            cart_header.entry_point[1],
            cart_header.entry_point[2],
            cart_header.entry_point[3],
        )
        fmt.printfln("Title: {}", string(cart_header.title[:]))
        fmt.printfln("CGB Flag: {:02X}", cart_header.cgb_flag)
        fmt.printfln(
            "New Licensee Code: {:02X}{:02X}",
            cart_header.new_licensee_code[0],
            cart_header.new_licensee_code[1],
        )
        fmt.printfln("SGB Flag: {:02X}", cart_header.sgb_flag)
        fmt.printfln("Type: {:.2x}", cart_header.cartridge_type)
        fmt.printfln("ROM SIZE: {:02X}", cart_header.rom_size)
        fmt.printfln("RAM SIZE: {:02X}", cart_header.ram_size)
        fmt.printfln("Destination Code: {:02X}", cart_header.destination_code)
        fmt.printfln("Old Licensee Code: {:02X}", cart_header.old_licensee_code)
        fmt.printfln("Version number: {:02X}", cart_header.mask_rom_version_number)
        fmt.printfln("Header checksum: {:02X}", cart_header.header_checksum)
        fmt.printfln(
            "Global Checksum: {:02X}{:02X}",
            cart_header.global_checksum_hi,
            cart_header.global_checksum_lo,
        )
    }
}

cart_load :: proc (filename: string) -> (ok: bool) {
    file, open_err := os.open(filename)
    if open_err != nil {
        log.errorf("Failed to open file: {}", filename)
        return false
    }

    defer os.close(file)

    size, size_err := os.file_size(file)
    if size_err != nil {
        log.errorf("Failed to get file size: {}", filename)
        return false
    }

    os.read_at_least(file, cart_data[:], auto_cast size)
    cart_header = auto_cast &cart_data[0x100]

    return true
}

