package odin_gb

import "base:runtime"

import "core:os"
import "core:log"
import "core:fmt"
import "core:sync"

import "vendor:sdl3"

cartridge_data: [1024 * 1024]u8

CartType :: enum u8 {
    NO_MBC,
    MBC1,
    MBC2,
    MBC3,
    MBC4,
    MBC5,
    MBC6,
    MBC7,
    MMM01,
    POCKET_CAMERA,
    BANDAI_TAMA5,
    HUC3,
    HUC1,
    UNUSED,
}

CartHeader :: struct {
    entry_point            : [4]u8,
    nintendo_logo          : [48]u8,
    title                  : [15]u8,
    cgb_flag               : u8,
    new_licensee_code      : [2]u8,
    sgb_flag               : u8,
    type                    : u8,
    rom_size               : u8,
    ram_size               : u8,
    destination_code       : u8,
    old_licensee_code      : u8,
    mask_rom_version_number: u8,
    header_checksum        : u8,
    global_checksum_hi     : u8,
    global_checksum_lo     : u8,
}

CartTypeInfo :: struct {
    type:               CartType,
    has_ram:            bool,
    has_battery:        bool,
    has_timer:          bool,
    has_rumble:         bool,
    has_accelerometer:  bool,
    readable_name:      string,
}

cart_data_types :[256]CartTypeInfo= {
    // TYPE   |  RAM  |BATTERY| TIMER | RUMBLE| ACCELL| READABLE NAME
    { .NO_MBC,  false,  false,  false,  false,  false, "No MBC - ROM Only"              }, // 0x00
    { .MBC1,    false,  false,  false,  false,  false, "MBC1"                           }, // 0x01
    { .MBC1,    true,   false,  false,  false,  false, "MBC1 + RAM"                     }, // 0x02
    { .MBC1,    true,   true,   false,  false,  false, "MBC1 + RAM + Battery"           }, // 0x03
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x04
    { .MBC2,    false,  false,  false,  false,  false, "MBC2"                           }, // 0x05
    { .MBC2,    true,   true,   false,  false,  false, "MBC2 + RAM + Battery"           }, // 0x06
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x07
    { .NO_MBC,  true,   false,  false,  false,  false, "ROM + RAM"                      }, // 0x08
    { .NO_MBC,  true,   true,   false,  false,  false, "ROM + RAM + Battery"            }, // 0x09
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x0A
    { .MMM01,   false,  false,  false,  false,  false, "MMM01"                          }, // 0x0B
    { .MMM01,   true,   false,  false,  false,  false, "MMM01 + RAM"                    }, // 0x0C
    { .MMM01,   true,   true,   false,  false,  false, "MMM01 + RAM + Battery"          }, // 0x0D
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x0E
    { .MBC3,    false,  true,   true,   false,  false, "MBC3 + Timer + Battery"         }, // 0x0F
    { .MBC3,    true,   true,   true,   false,  false, "MBC3 + RAM + Timer + Battery"   }, // 0x10
    { .MBC3,    false,  false,  false,  false,  false, "MBC3"                           }, // 0x11
    { .MBC3,    true,   false,  false,  false,  false, "MBC3 + RAM"                     }, // 0x12
    { .MBC3,    true,   true,   false,  false,  false, "MBC3 + RAM + Battery"           }, // 0x13
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x14
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x15
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x16
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x17
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x18
    { .MBC5,    false,  false,  false,  false,  false, "MBC5"                           }, // 0x19
    { .MBC5,    true,   false,  false,  false,  false, "MBC5 + RAM"                     }, // 0x1A
    { .MBC5,    true,   true,   false,  false,  false, "MBC5 + RAM + Battery"           }, // 0x1B
    { .MBC5,    true,   true,   false,  true,   false, "MBC5 + Rumble"                  }, // 0x1C
    { .MBC5,    true,   false,  false,  true,   false, "MBC5 + RAM + Rumble"            }, // 0x1D
    { .MBC5,    true,   true,   false,  true,   false, "MBC5 + RAM + Battery + Rumble"  }, // 0x1E
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x1F
    { .MBC6,    true,   true,   false,  false,  false, "MBC6 + RAM +  Battery"          }, // 0x20
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x21
    { .MBC7,    true,   true,   false,  false,  true,  "MBC7 + RAM +  Battery + Accelerometer" }, // 0x22
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x23
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x24
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x25
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x26
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x27
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x28
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x29
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x2A
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x2B
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x2C
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x2D
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x2E
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x2F
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x30
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x31
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x32
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x33
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x34
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x35
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x36
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x37
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x38
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x39
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x3A
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x3B
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x3C
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x3D
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x3E
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x3F
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x40
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x41
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x42
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x43
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x44
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x45
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x46
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x47
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x48
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x49
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x4A
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x4B
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x4C
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x4D
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x4E
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x4F
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x50
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x51
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x52
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x53
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x54
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x55
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x56
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x57
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x58
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x59
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x5A
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x5B
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x5C
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x5D
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x5E
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x5F
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x60
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x61
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x62
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x63
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x64
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x65
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x66
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x67
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x68
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x69
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x6A
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x6B
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x6C
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x6D
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x6E
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x6F
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x70
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x71
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x72
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x73
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x74
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x75
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x76
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x77
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x78
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x79
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x7A
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x7B
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x7C
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x7D
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x7E
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x7F
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x80
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x81
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x82
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x83
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x84
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x85
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x86
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x87
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x88
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x89
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x8A
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x8B
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x8C
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x8D
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x8E
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x8F
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x90
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x91
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x92
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x93
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x94
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x95
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x96
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x97
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x98
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x99
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x9A
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x9B
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x9C
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x9D
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x9E
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0x9F
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xA0
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xA1
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xA2
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xA3
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xA4
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xA5
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xA6
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xA7
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xA8
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xA9
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xAA
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xAB
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xAC
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xAD
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xAE
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xAF
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xB0
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xB1
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xB2
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xB3
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xB4
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xB5
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xB6
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xB7
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xB8
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xB9
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xBA
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xBB
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xBC
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xBD
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xBE
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xBF
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xC0
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xC1
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xC2
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xC3
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xC4
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xC5
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xC6
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xC7
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xC8
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xC9
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xCA
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xCB
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xCC
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xCD
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xCE
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xCF
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xD0
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xD1
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xD2
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xD3
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xD4
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xD5
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xD6
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xD7
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xD8
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xD9
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xDA
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xDB
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xDC
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xDD
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xDE
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xDF
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xE0
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xE1
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xE2
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xE3
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xE4
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xE5
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xE6
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xE7
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xE8
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xE9
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xEA
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xEB
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xEC
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xED
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xEE
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xEF
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xF0
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xF1
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xF2
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xF3
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xF4
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xF5
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xF6
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xF7
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xF8
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xF9
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xFA
    { .UNUSED,  false,  false,  false,  false,  false, "Unused"                         }, // 0xFB
    { .POCKET_CAMERA,  false,  false,  false,  false,  false, "Pocket Camera"           }, // 0xFC
    { .BANDAI_TAMA5,  false,  false,  false,  false,  false, "Bandai Tama5"             }, // 0xFD
    { .HUC3,    false,  false,  false,  false,  false, "HuC3"                           }, // 0xFE
    { .HUC1,    true,   true,   false,  false,  false, "HuC1 + RAM + Battery"           }, // 0xFF
}

cartridge_header: ^CartHeader

@(private="file")
cart_file_name: [2048]u8

@(private="file")
has_cart_file_name: bool

@(private="file")
cart_dialog_mutex: sync.Mutex

cart_open_file :: proc () {
    file_dialog_callback :: proc "c" (userdata: rawptr, filelist: [^]cstring, filter: i32) {
        if filelist == nil {
            context = runtime.default_context()
            context.logger = (cast(^runtime.Logger)userdata)^
            log.error("Dialog file called with error: {}", cast(string)(sdl3.GetError()))
            os.exit(1)
        }

        sync.mutex_guard(&cart_dialog_mutex)
        if filelist[0] == nil {
            os.exit(1)
        } else {
            has_cart_file_name = true
            _ = sdl3.strlcpy(&cart_file_name[0], filelist[0], len(cart_file_name))
        }
    }

    filters := []sdl3.DialogFileFilter{{"Game Boy ROMs", "gb"}}

    for {
        has_cart_file_name = false

        logger := context.logger
        sdl3.ShowOpenFileDialog(
            file_dialog_callback,
            &logger,
            root_window,
            raw_data(filters),
            cast(i32)len(filters),
            cast(cstring)sdl3.GetCurrentDirectory(),
            false,
        )

        for {
            {
                sync.mutex_guard(&cart_dialog_mutex)
                if has_cart_file_name {
                    if cart_load(string(cart_file_name[:])) {
                        return
                    } else {
                        break
                    }
                }
            }
            sdl3.PumpEvents()
            sdl3.Delay(16)
        }
    }
}

cart_print_info :: proc () {
    if cartridge_header != nil {
        fmt.printfln(
            "Entry Point: {:02X}{:02X}{:02X}{:02X}",
            cartridge_header.entry_point[0],
            cartridge_header.entry_point[1],
            cartridge_header.entry_point[2],
            cartridge_header.entry_point[3],
        )
        fmt.printfln("Title: {}", string(cartridge_header.title[:]))
        fmt.printfln("CGB Flag: {:02X}", cartridge_header.cgb_flag)
        fmt.printfln(
            "New Licensee Code: {:02X}{:02X}",
            cartridge_header.new_licensee_code[0],
            cartridge_header.new_licensee_code[1],
        )
        fmt.printfln("SGB Flag: {:02X}", cartridge_header.sgb_flag)
        fmt.printfln(
            "Type: {:02X} ({})",
            cartridge_header.type,
            cart_data_types[cartridge_header.type].readable_name,
        )
        fmt.printfln("ROM SIZE: {:02X}", cartridge_header.rom_size)
        fmt.printfln("RAM SIZE: {:02X}", cartridge_header.ram_size)
        fmt.printfln("Destination Code: {:02X}", cartridge_header.destination_code)
        fmt.printfln("Old Licensee Code: {:02X}", cartridge_header.old_licensee_code)
        fmt.printfln("Version number: {:02X}", cartridge_header.mask_rom_version_number)
        fmt.printfln("Header checksum: {:02X}", cartridge_header.header_checksum)
        fmt.printfln(
            "Global Checksum: {:02X}{:02X}",
            cartridge_header.global_checksum_hi,
            cartridge_header.global_checksum_lo,
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

    os.read_at_least(file, cartridge_data[:], auto_cast size)
    cartridge_header = auto_cast &cartridge_data[0x100]

    return true
}

