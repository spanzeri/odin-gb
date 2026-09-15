package odin_gb

CpuInstructionProc :: #type proc ()

CpuInstructionInfo :: struct {
    disassembly:    string,
    operand_length: u8,
    procedure:      CpuInstructionProc,
}

CPU_INSTRUCTIONS := [256]CpuInstructionInfo{
    { "NOP",            0,  cpu_noop        }, // 0x00
    { "LD BC,n16",      2,  cpu_ld_bc_n16   }, // 0x01
    { "LD [BC],a",      0,  cpu_ld_bc_a     }, // 0x02
    { "INC BC",         0,  cpu_inc_bc      }, // 0x03
    { "INC B",          0,  cpu_inc_b       }, // 0x04
    { "DEC B",          0,  cpu_dec_b       }, // 0x05
    { "LD B,n8",        1,  cpu_ld_b_n8     }, // 0x06
    { "RLCA",           0,  cpu_rlca        }, // 0x07
    { "LD [a16],SP",    2,  cpu_ld_16_sp    }, // 0x08
    { "ADD HL,BC",      0,  cpu_add_hl_bc   }, // 0x09
    { "LD A,[BC]",      0,  cpu_ld_a_bc     }, // 0x0A
    { "DEC BC",         0,  cpu_dec_bc      }, // 0x0B
    { "INC C",          0,  cpu_inc_c       }, // 0x0C
    { "DEC C",          0,  cpu_dec_c       }, // 0x0D
    { "LD C,n8",        1,  cpu_ld_c_n8     }, // 0x0E
    { "RRCA",           0,  cpu_rrca        }, // 0x0F
    { "STOP n8",        1,  cpu_stop        }, // 0x10
    { "LD DE,n16",      2,  cpu_ld_de_n16   }, // 0x11
    { "LD [DE],a",      0,  cpu_ld_de_a     }, // 0x12
    { "INC DE",         0,  cpu_inc_de      }, // 0x13
    { "INC D",          0,  cpu_inc_d       }, // 0x14
    { "DEC D",          0,  cpu_dec_d       }, // 0x15
    { "LD D,n8",        1,  cpu_ld_d_n8     }, // 0x16
    { "RLA",            0,  cpu_rla         }, // 0x17
    { "JR e8",          1,  cpu_jr          }, // 0x18
    { "ADD HL,DE",      0,  cpu_add_hl_de   }, // 0x19
    { "LD A,[DE]",      0,  cpu_ld_a_de     }, // 0x1A
    { "DEC DE",         0,  cpu_dec_de      }, // 0x1B
    { "INC E",          0,  cpu_inc_e       }, // 0x1C
    { "DEC E",          0,  cpu_dec_e       }, // 0x1D
    { "LD E,n8",        1,  cpu_ld_e_n8     }, // 0x1E
    { "RRA",            0,  cpu_rra         }, // 0x1F
    { "JR NZ,e8",       1,  cpu_jr_nz       }, // 0x20
    { "LD HL,n16",      2,  cpu_ld_hl_n16   }, // 0x21
    { "LD [HL+],a",     0,  cpu_ld_hl_inc_a }, // 0x22
    { "INC HL",         0,  cpu_inc_hl      }, // 0x23
    { "INC H",          0,  cpu_inc_h       }, // 0x24
    { "DEC H",          0,  cpu_dec_h       }, // 0x25
    { "LD H,n8",        1,  cpu_ld_h_n8     }, // 0x26
    { "DAA",            0,  cpu_daa         }, // 0x27
    { "JR Z,e8",        1,  cpu_jr_z        }, // 0x28
    { "ADD HL,HL",      0,  cpu_add_hl_hl   }, // 0x29
    { "LD A,[HL+]",     0,  cpu_ld_a_hl_inc }, // 0x2A
    { "DEC HL",         0,  cpu_dec_hl      }, // 0x2B
    { "INC L",          0,  cpu_inc_l       }, // 0x2C
    { "DEC L",          0,  cpu_dec_l       }, // 0x2D
    { "LD L,n8",        1,  cpu_ld_l_n8     }, // 0x2E
    { "CPL",            0,  cpu_cpl         }, // 0x2F
    { "JR NC,e8",       1,  cpu_jr_nc       }, // 0x30
    { "LD SP,n16",      2,  cpu_ld_sp_n16   }, // 0x31
    { "LD [HL-],a",     0,  cpu_ld_hl_dec_a }, // 0x32
    { "INC SP",         0,  cpu_inc_sp      }, // 0x33
    { "INC [HL]",       0,  cpu_inc_hl_ptr  }, // 0x34
    { "DEC [HL]",       0,  cpu_dec_hl_ptr  }, // 0x35
    { "LD [HL],n8",     1,  cpu_ld_hl_ptr_n8}, // 0x36
    { "SCF",            0,  cpu_scf         }, // 0x37
    { "JR C,e8",        1,  cpu_jr_c        }, // 0x38
    { "ADD HL,SP",      0,  cpu_add_hl_sp   }, // 0x39
    { "LD A,[HL-]",     0,  cpu_ld_a_hl_dec }, // 0x3A
    { "DEC SP",         0,  cpu_dec_sp      }, // 0x3B
    { "INC A",          0,  cpu_inc_a       }, // 0x3C
    { "DEC A",          0,  cpu_dec_a       }, // 0x3D
    { "LD A,n8",        1,  cpu_ld_a_n8     }, // 0x3E
    { "CCF",            0,  cpu_ccf         }, // 0x3F
    { "LD B,B",         0,  cpu_ld_b_b      }, // 0x40
    { "LD B,C",         0,  cpu_ld_b_c      }, // 0x41
    { "LD B,D",         0,  cpu_ld_b_d      }, // 0x42
    { "LD B,E",         0,  cpu_ld_b_e      }, // 0x43
    { "LD B,H",         0,  cpu_ld_b_h      }, // 0x44
    { "LD B,L",         0,  cpu_ld_b_l      }, // 0x45
    { "LD B,[HL]",      0,  cpu_ld_b_hl     }, // 0x46
    { "LD B,A",         0,  cpu_ld_b_a      }, // 0x47
    { "LD C,B",         0,  cpu_ld_c_b      }, // 0x48
    { "LD C,C",         0,  cpu_ld_c_c      }, // 0x49
    { "LD C,D",         0,  cpu_ld_c_d      }, // 0x4A
    { "LD C,E",         0,  cpu_ld_c_e      }, // 0x4B
    { "LD C,H",         0,  cpu_ld_c_h      }, // 0x4C
    { "LD C,L",         0,  cpu_ld_c_l      }, // 0x4D
    { "LD C,[HL]",      0,  cpu_ld_c_hl     }, // 0x4E
    { "LD C,A",         0,  cpu_ld_c_a      }, // 0x4F
    { "LD D,B",         0,  cpu_ld_d_b      }, // 0x50
    { "LD D,C",         0,  cpu_ld_d_c      }, // 0x51
    { "LD D,D",         0,  cpu_ld_d_d      }, // 0x52
    { "LD D,E",         0,  cpu_ld_d_e      }, // 0x53
    { "LD D,H",         0,  cpu_ld_d_h      }, // 0x54
    { "LD D,L",         0,  cpu_ld_d_l      }, // 0x55
    { "LD D,[HL]",      0,  cpu_ld_d_hl     }, // 0x56
    { "LD D,A",         0,  cpu_ld_d_a      }, // 0x57
    { "LD E,B",         0,  cpu_ld_e_b      }, // 0x58
    { "LD E,C",         0,  cpu_ld_e_c      }, // 0x59
    { "LD E,D",         0,  cpu_ld_e_d      }, // 0x5A
    { "LD E,E",         0,  cpu_ld_e_e      }, // 0x5B
    { "LD E,H",         0,  cpu_ld_e_h      }, // 0x5C
    { "LD E,L",         0,  cpu_ld_e_l      }, // 0x5D
    { "LD E,[HL]",      0,  cpu_ld_e_hl     }, // 0x5E
    { "LD E,A",         0,  cpu_ld_e_a      }, // 0x5F
    { "LD H,B",         0,  cpu_ld_h_b      }, // 0x60
    { "LD H,C",         0,  cpu_ld_h_c      }, // 0x61
    { "LD H,D",         0,  cpu_ld_h_d      }, // 0x62
    { "LD H,E",         0,  cpu_ld_h_e      }, // 0x63
    { "LD H,H",         0,  cpu_ld_h_h      }, // 0x64
    { "LD H,L",         0,  cpu_ld_h_l      }, // 0x65
    { "LD H,[HL]",      0,  cpu_ld_h_hl     }, // 0x66
    { "LD H,A",         0,  cpu_ld_h_a      }, // 0x67
    { "LD L,B",         0,  cpu_ld_l_b      }, // 0x68
    { "LD L,C",         0,  cpu_ld_l_c      }, // 0x69
    { "LD L,D",         0,  cpu_ld_l_d      }, // 0x6A
    { "LD L,E",         0,  cpu_ld_l_e      }, // 0x6B
    { "LD L,H",         0,  cpu_ld_l_h      }, // 0x6C
    { "LD L,L",         0,  cpu_ld_l_l      }, // 0x6D
    { "LD L,[HL]",      0,  cpu_ld_l_hl     }, // 0x6E
    { "LD L,A",         0,  cpu_ld_l_a      }, // 0x6F
    { "LD [HL],B",      0,  cpu_ld_hl_b     }, // 0x70
    { "LD [HL],C",      0,  cpu_ld_hl_c     }, // 0x71
    { "LD [HL],D",      0,  cpu_ld_hl_d     }, // 0x72
    { "LD [HL],E",      0,  cpu_ld_hl_e     }, // 0x73
    { "LD [HL],H",      0,  cpu_ld_hl_h     }, // 0x74
    { "LD [HL],L",      0,  cpu_ld_hl_l     }, // 0x75
    { "HALT",           0,  cpu_halt        }, // 0x76
    { "LD [HL],A",      0,  cpu_ld_hl_a     }, // 0x77
    { "LD A,B",         0,  cpu_ld_a_b      }, // 0x78
    { "LD A,C",         0,  cpu_ld_a_c      }, // 0x79
    { "LD A,D",         0,  cpu_ld_a_d      }, // 0x7A
    { "LD A,E",         0,  cpu_ld_a_e      }, // 0x7B
    { "LD A,H",         0,  cpu_ld_a_h      }, // 0x7C
    { "LD A,L",         0,  cpu_ld_a_l      }, // 0x7D
    { "LD A,[HL]",      0,  cpu_ld_a_hl     }, // 0x7E
    { "LD A,A",         0,  cpu_ld_a_a      }, // 0x7F
    { "ADD A,B",        0,  cpu_add_b       }, // 0x80
    { "ADD A,C",        0,  cpu_add_c       }, // 0x81
    { "ADD A,D",        0,  cpu_add_d       }, // 0x82
    { "ADD A,E",        0,  cpu_add_e       }, // 0x83
    { "ADD A,H",        0,  cpu_add_h       }, // 0x84
    { "ADD A,L",        0,  cpu_add_l       }, // 0x85
    { "ADD A,[HL]",     0,  cpu_add_ptr_hl  }, // 0x86
    { "ADD A,A",        0,  cpu_add_a       }, // 0x87
    { "ADC A,B",        0,  cpu_adc_b       }, // 0x88
    { "ADC A,C",        0,  cpu_adc_c       }, // 0x89
    { "ADC A,D",        0,  cpu_adc_d       }, // 0x8A
    { "ADC A,E",        0,  cpu_adc_e       }, // 0x8B
    { "ADC A,H",        0,  cpu_adc_h       }, // 0x8C
    { "ADC A,L",        0,  cpu_adc_l       }, // 0x8D
    { "ADC A,[HL]",     0,  cpu_adc_ptr_hl  }, // 0x8E
    { "ADC A,A",        0,  cpu_adc_a       }, // 0x8F
    { "SUB A,B",        0,  cpu_sub_b       }, // 0x90
    { "SUB A,C",        0,  cpu_sub_c       }, // 0x91
    { "SUB A,D",        0,  cpu_sub_d       }, // 0x92
    { "SUB A,E",        0,  cpu_sub_e       }, // 0x93
    { "SUB A,H",        0,  cpu_sub_h       }, // 0x94
    { "SUB A,L",        0,  cpu_sub_l       }, // 0x95
    { "SUB A,[HL]",     0,  cpu_sub_ptr_hl  }, // 0x96
    { "SUB A,A",        0,  cpu_sub_a       }, // 0x97
    { "SBC A,B",        0,  cpu_sbc_b       }, // 0x98
    { "SBC A,C",        0,  cpu_sbc_c       }, // 0x99
    { "SBC A,D",        0,  cpu_sbc_d       }, // 0x9A
    { "SBC A,E",        0,  cpu_sbc_e       }, // 0x9B
    { "SBC A,H",        0,  cpu_sbc_h       }, // 0x9C
    { "SBC A,L",        0,  cpu_sbc_l       }, // 0x9D
    { "SBC A,[HL]",     0,  cpu_sbc_ptr_hl  }, // 0x9E
    { "SBC A,A",        0,  cpu_sbc_a       }, // 0x9F
    { "AND A,B",        0,  cpu_and_b       }, // 0xA0
    { "AND A,C",        0,  cpu_and_c       }, // 0xA1
    { "AND A,D",        0,  cpu_and_d       }, // 0xA2
    { "AND A,E",        0,  cpu_and_e       }, // 0xA3
    { "AND A,H",        0,  cpu_and_h       }, // 0xA4
    { "AND A,L",        0,  cpu_and_l       }, // 0xA5
    { "AND A,[HL]",     0,  cpu_and_ptr_hl  }, // 0xA6
    { "AND A,A",        0,  cpu_and_a       }, // 0xA7
    { "XOR A,B",        0,  cpu_xor_b       }, // 0xA8
    { "XOR A,C",        0,  cpu_xor_c       }, // 0xA9
    { "XOR A,D",        0,  cpu_xor_d       }, // 0xAA
    { "XOR A,E",        0,  cpu_xor_e       }, // 0xAB
    { "XOR A,H",        0,  cpu_xor_h       }, // 0xAC
    { "XOR A,L",        0,  cpu_xor_l       }, // 0xAD
    { "XOR A,[HL]",     0,  cpu_xor_ptr_hl  }, // 0xAE
    { "XOR A,A",        0,  cpu_xor_a       }, // 0xAF
    { "OR A,B",         0,  cpu_or_b        }, // 0xB0
    { "OR A,C",         0,  cpu_or_c        }, // 0xB1
    { "OR A,D",         0,  cpu_or_d        }, // 0xB2
    { "OR A,E",         0,  cpu_or_e        }, // 0xB3
    { "OR A,H",         0,  cpu_or_h        }, // 0xB4
    { "OR A,L",         0,  cpu_or_l        }, // 0xB5
    { "OR A,[HL]",      0,  cpu_or_ptr_hl   }, // 0xB6
    { "OR A,A",         0,  cpu_or_a        }, // 0xB7
    { "CP A,B",         0,  cpu_cp_b        }, // 0xB8
    { "CP A,C",         0,  cpu_cp_c        }, // 0xB9
    { "CP A,D",         0,  cpu_cp_d        }, // 0xBA
    { "CP A,E",         0,  cpu_cp_e        }, // 0xBB
    { "CP A,H",         0,  cpu_cp_h        }, // 0xBC
    { "CP A,L",         0,  cpu_cp_l        }, // 0xBD
    { "CP A,[HL]",      0,  cpu_cp_ptr_hl   }, // 0xBE
    { "CP A,A",         0,  cpu_cp_a        }, // 0xBF
    { "RET NZ",         0,  cpu_ret_nz      }, // 0xC0
    { "POP BC",         0,  cpu_pop_bc      }, // 0xC1
    { "JP NZ,a16",      2,  cpu_jp_nz       }, // 0xC2
    { "JP a16",         2,  cpu_jp_a16      }, // 0xC3
    { "CALL NZ,a16",    2,  cpu_call_nz     }, // 0xC4
    { "PUSH BC",        0,  cpu_push_bc     }, // 0xC5
    { "ADD A,n8",       1,  cpu_add_n8      }, // 0xC6
    { "RST 00",         0,  cpu_rst_00      }, // 0xC7
    { "RET Z",          0,  cpu_ret_z       }, // 0xC8
    { "RET",            0,  cpu_ret         }, // 0xC9
    { "JP Z,a16",       2,  cpu_jp_z        }, // 0xCA
    { "PREFIX",         0,  nil             }, // 0xCB
    { "CALL Z,a16",     2,  cpu_call_z      }, // 0xCC
    { "CALL a16",       2,  cpu_call        }, // 0xCD
    { "ADC A,n8",       1,  cpu_adc_n8      }, // 0xCE
    { "RST 08",         0,  cpu_rst_08      }, // 0xCF
    { "RET NC",         0,  cpu_ret_nc      }, // 0xD0
    { "POP DE",         0,  cpu_pop_de      }, // 0xD1
    { "JP NC,a16",      2,  cpu_jp_nc       }, // 0xD2
    { "_",              0,  nil             }, // 0xD3
    { "CALL NC,a16",    2,  cpu_call_nc     }, // 0xD4
    { "PUSH DE",        0,  cpu_push_de     }, // 0xD5
    { "SUB A,n8",       1,  cpu_sub_n8      }, // 0xD6
    { "RST 10",         0,  cpu_rst_10      }, // 0xD7
    { "RET C",          0,  cpu_ret_c       }, // 0xD8
    { "RETI",           0,  cpu_reti        }, // 0xD9
    { "JP C,a16",       2,  cpu_jp_c        }, // 0xDA
    { "_",              0,  nil             }, // 0xDB
    { "CALL C,a16",     2,  cpu_call_c      }, // 0xDC
    { "_",              0,  nil             }, // 0xDD
    { "SBC A,n8",       1,  cpu_sbc_n8      }, // 0xDE
    { "RST 18",         0,  cpu_rst_18      }, // 0xDF
    { "LDH [a8],A",     1,  cpu_ldh_n8_a    }, // 0xE0
    { "POP HL",         0,  cpu_pop_hl      }, // 0xE1
    { "LDH [C],A",      0,  cpu_ldh_c_a     }, // 0xE2
    { "_",              0,  nil             }, // 0xE3
    { "_",              0,  nil             }, // 0xE4
    { "PUSH HL",        0,  cpu_push_hl     }, // 0xE5
    { "AND A,n8",       1,  cpu_and_n8      }, // 0xE6
    { "RST 20",         0,  cpu_rst_20      }, // 0xE7
    { "ADD SP,e8",      1,  cpu_add_sp      }, // 0xE8
    { "JP HL",          0,  cpu_jp_hl       }, // 0xE9
    { "LD [a16],A",     2,  cpu_ld_ptr_a    }, // 0xEA
    { "_",              0,  nil             }, // 0xEB
    { "_",              0,  nil             }, // 0xEC
    { "_",              0,  nil             }, // 0xED
    { "XOR A,n8",       1,  cpu_xor_n8      }, // 0xEE
    { "RST 28",         0,  cpu_rst_28      }, // 0xEF
    { "LDH A,[a8]",     1,  cpu_ldh_a_n8    }, // 0xF0
    { "POP AF",         0,  cpu_pop_af      }, // 0xF1
    { "LDH A,[C]",      0,  cpu_ldh_a_c     }, // 0xF2
    { "DI",             0,  cpu_di          }, // 0xF3
    { "_",              0,  nil             }, // 0xF4
    { "PUSH AF",        0,  cpu_push_af     }, // 0xF5
    { "OR A,n8",        1,  cpu_or_n8       }, // 0xF6
    { "RST 30",         0,  cpu_rst_30      }, // 0xF7
    { "LD HL,SP+e8",    1,  cpu_ld_hl_spe8  }, // 0xF8
    { "LD SP,HL",       0,  cpu_ld_sp_hl    }, // 0xF9
    { "LD A,[a16]",     2,  cpu_ld_a_ptr    }, // 0xFA
    { "EI",             0,  cpu_ei          }, // 0xFB
    { "_",              0,  nil             }, // 0xFC
    { "_",              0,  nil             }, // 0xFD
    { "CP A,n8",        1,  cpu_cp_n8       }, // 0xFE
    { "RST $38",        0,  cpu_rst_38      }, // 0xFF
}

CPU_CB_INSTRUCTIONS :[256]CpuInstructionInfo: {
    { "", 0, nil }, // 0x00
    { "", 0, nil }, // 0x01
    { "", 0, nil }, // 0x02
    { "", 0, nil }, // 0x03
    { "", 0, nil }, // 0x04
    { "", 0, nil }, // 0x05
    { "", 0, nil }, // 0x06
    { "", 0, nil }, // 0x07
    { "", 0, nil }, // 0x08
    { "", 0, nil }, // 0x09
    { "", 0, nil }, // 0x0A
    { "", 0, nil }, // 0x0B
    { "", 0, nil }, // 0x0C
    { "", 0, nil }, // 0x0D
    { "", 0, nil }, // 0x0E
    { "", 0, nil }, // 0x0F
    { "", 0, nil }, // 0x10
    { "", 0, nil }, // 0x11
    { "", 0, nil }, // 0x12
    { "", 0, nil }, // 0x13
    { "", 0, nil }, // 0x14
    { "", 0, nil }, // 0x15
    { "", 0, nil }, // 0x16
    { "", 0, nil }, // 0x17
    { "", 0, nil }, // 0x18
    { "", 0, nil }, // 0x19
    { "", 0, nil }, // 0x1A
    { "", 0, nil }, // 0x1B
    { "", 0, nil }, // 0x1C
    { "", 0, nil }, // 0x1D
    { "", 0, nil }, // 0x1E
    { "", 0, nil }, // 0x1F
    { "", 0, nil }, // 0x20
    { "", 0, nil }, // 0x21
    { "", 0, nil }, // 0x22
    { "", 0, nil }, // 0x23
    { "", 0, nil }, // 0x24
    { "", 0, nil }, // 0x25
    { "", 0, nil }, // 0x26
    { "", 0, nil }, // 0x27
    { "", 0, nil }, // 0x28
    { "", 0, nil }, // 0x29
    { "", 0, nil }, // 0x2A
    { "", 0, nil }, // 0x2B
    { "", 0, nil }, // 0x2C
    { "", 0, nil }, // 0x2D
    { "", 0, nil }, // 0x2E
    { "", 0, nil }, // 0x2F
    { "", 0, nil }, // 0x30
    { "", 0, nil }, // 0x31
    { "", 0, nil }, // 0x32
    { "", 0, nil }, // 0x33
    { "", 0, nil }, // 0x34
    { "", 0, nil }, // 0x35
    { "", 0, nil }, // 0x36
    { "", 0, nil }, // 0x37
    { "", 0, nil }, // 0x38
    { "", 0, nil }, // 0x39
    { "", 0, nil }, // 0x3A
    { "", 0, nil }, // 0x3B
    { "", 0, nil }, // 0x3C
    { "", 0, nil }, // 0x3D
    { "", 0, nil }, // 0x3E
    { "", 0, nil }, // 0x3F
    { "", 0, nil }, // 0x40
    { "", 0, nil }, // 0x41
    { "", 0, nil }, // 0x42
    { "", 0, nil }, // 0x43
    { "", 0, nil }, // 0x44
    { "", 0, nil }, // 0x45
    { "", 0, nil }, // 0x46
    { "", 0, nil }, // 0x47
    { "", 0, nil }, // 0x48
    { "", 0, nil }, // 0x49
    { "", 0, nil }, // 0x4A
    { "", 0, nil }, // 0x4B
    { "", 0, nil }, // 0x4C
    { "", 0, nil }, // 0x4D
    { "", 0, nil }, // 0x4E
    { "", 0, nil }, // 0x4F
    { "", 0, nil }, // 0x50
    { "", 0, nil }, // 0x51
    { "", 0, nil }, // 0x52
    { "", 0, nil }, // 0x53
    { "", 0, nil }, // 0x54
    { "", 0, nil }, // 0x55
    { "", 0, nil }, // 0x56
    { "", 0, nil }, // 0x57
    { "", 0, nil }, // 0x58
    { "", 0, nil }, // 0x59
    { "", 0, nil }, // 0x5A
    { "", 0, nil }, // 0x5B
    { "", 0, nil }, // 0x5C
    { "", 0, nil }, // 0x5D
    { "", 0, nil }, // 0x5E
    { "", 0, nil }, // 0x5F
    { "", 0, nil }, // 0x60
    { "", 0, nil }, // 0x61
    { "", 0, nil }, // 0x62
    { "", 0, nil }, // 0x63
    { "", 0, nil }, // 0x64
    { "", 0, nil }, // 0x65
    { "", 0, nil }, // 0x66
    { "", 0, nil }, // 0x67
    { "", 0, nil }, // 0x68
    { "", 0, nil }, // 0x69
    { "", 0, nil }, // 0x6A
    { "", 0, nil }, // 0x6B
    { "", 0, nil }, // 0x6C
    { "", 0, nil }, // 0x6D
    { "", 0, nil }, // 0x6E
    { "", 0, nil }, // 0x6F
    { "", 0, nil }, // 0x70
    { "", 0, nil }, // 0x71
    { "", 0, nil }, // 0x72
    { "", 0, nil }, // 0x73
    { "", 0, nil }, // 0x74
    { "", 0, nil }, // 0x75
    { "", 0, nil }, // 0x76
    { "", 0, nil }, // 0x77
    { "", 0, nil }, // 0x78
    { "", 0, nil }, // 0x79
    { "", 0, nil }, // 0x7A
    { "", 0, nil }, // 0x7B
    { "", 0, nil }, // 0x7C
    { "", 0, nil }, // 0x7D
    { "", 0, nil }, // 0x7E
    { "", 0, nil }, // 0x7F
    { "", 0, nil }, // 0x80
    { "", 0, nil }, // 0x81
    { "", 0, nil }, // 0x82
    { "", 0, nil }, // 0x83
    { "", 0, nil }, // 0x84
    { "", 0, nil }, // 0x85
    { "", 0, nil }, // 0x86
    { "", 0, nil }, // 0x87
    { "", 0, nil }, // 0x88
    { "", 0, nil }, // 0x89
    { "", 0, nil }, // 0x8A
    { "", 0, nil }, // 0x8B
    { "", 0, nil }, // 0x8C
    { "", 0, nil }, // 0x8D
    { "", 0, nil }, // 0x8E
    { "", 0, nil }, // 0x8F
    { "", 0, nil }, // 0x90
    { "", 0, nil }, // 0x91
    { "", 0, nil }, // 0x92
    { "", 0, nil }, // 0x93
    { "", 0, nil }, // 0x94
    { "", 0, nil }, // 0x95
    { "", 0, nil }, // 0x96
    { "", 0, nil }, // 0x97
    { "", 0, nil }, // 0x98
    { "", 0, nil }, // 0x99
    { "", 0, nil }, // 0x9A
    { "", 0, nil }, // 0x9B
    { "", 0, nil }, // 0x9C
    { "", 0, nil }, // 0x9D
    { "", 0, nil }, // 0x9E
    { "", 0, nil }, // 0x9F
    { "", 0, nil }, // 0xA0
    { "", 0, nil }, // 0xA1
    { "", 0, nil }, // 0xA2
    { "", 0, nil }, // 0xA3
    { "", 0, nil }, // 0xA4
    { "", 0, nil }, // 0xA5
    { "", 0, nil }, // 0xA6
    { "", 0, nil }, // 0xA7
    { "", 0, nil }, // 0xA8
    { "", 0, nil }, // 0xA9
    { "", 0, nil }, // 0xAA
    { "", 0, nil }, // 0xAB
    { "", 0, nil }, // 0xAC
    { "", 0, nil }, // 0xAD
    { "", 0, nil }, // 0xAE
    { "", 0, nil }, // 0xAF
    { "", 0, nil }, // 0xB0
    { "", 0, nil }, // 0xB1
    { "", 0, nil }, // 0xB2
    { "", 0, nil }, // 0xB3
    { "", 0, nil }, // 0xB4
    { "", 0, nil }, // 0xB5
    { "", 0, nil }, // 0xB6
    { "", 0, nil }, // 0xB7
    { "", 0, nil }, // 0xB8
    { "", 0, nil }, // 0xB9
    { "", 0, nil }, // 0xBA
    { "", 0, nil }, // 0xBB
    { "", 0, nil }, // 0xBC
    { "", 0, nil }, // 0xBD
    { "", 0, nil }, // 0xBE
    { "", 0, nil }, // 0xBF
    { "", 0, nil }, // 0xC0
    { "", 0, nil }, // 0xC1
    { "", 0, nil }, // 0xC2
    { "", 0, nil }, // 0xC3
    { "", 0, nil }, // 0xC4
    { "", 0, nil }, // 0xC5
    { "", 0, nil }, // 0xC6
    { "", 0, nil }, // 0xC7
    { "", 0, nil }, // 0xC8
    { "", 0, nil }, // 0xC9
    { "", 0, nil }, // 0xCA
    { "", 0, nil }, // 0xCB
    { "", 0, nil }, // 0xCC
    { "", 0, nil }, // 0xCD
    { "", 0, nil }, // 0xCE
    { "", 0, nil }, // 0xCF
    { "", 0, nil }, // 0xD0
    { "", 0, nil }, // 0xD1
    { "", 0, nil }, // 0xD2
    { "", 0, nil }, // 0xD3
    { "", 0, nil }, // 0xD4
    { "", 0, nil }, // 0xD5
    { "", 0, nil }, // 0xD6
    { "", 0, nil }, // 0xD7
    { "", 0, nil }, // 0xD8
    { "", 0, nil }, // 0xD9
    { "", 0, nil }, // 0xDA
    { "", 0, nil }, // 0xDB
    { "", 0, nil }, // 0xDC
    { "", 0, nil }, // 0xDD
    { "", 0, nil }, // 0xDE
    { "", 0, nil }, // 0xDF
    { "", 0, nil }, // 0xE0
    { "", 0, nil }, // 0xE1
    { "", 0, nil }, // 0xE2
    { "", 0, nil }, // 0xE3
    { "", 0, nil }, // 0xE4
    { "", 0, nil }, // 0xE5
    { "", 0, nil }, // 0xE6
    { "", 0, nil }, // 0xE7
    { "", 0, nil }, // 0xE8
    { "", 0, nil }, // 0xE9
    { "", 0, nil }, // 0xEA
    { "", 0, nil }, // 0xEB
    { "", 0, nil }, // 0xEC
    { "", 0, nil }, // 0xED
    { "", 0, nil }, // 0xEE
    { "", 0, nil }, // 0xEF
    { "", 0, nil }, // 0xF0
    { "", 0, nil }, // 0xF1
    { "", 0, nil }, // 0xF2
    { "", 0, nil }, // 0xF3
    { "", 0, nil }, // 0xF4
    { "", 0, nil }, // 0xF5
    { "", 0, nil }, // 0xF6
    { "", 0, nil }, // 0xF7
    { "", 0, nil }, // 0xF8
    { "", 0, nil }, // 0xF9
    { "", 0, nil }, // 0xFA
    { "", 0, nil }, // 0xFB
    { "", 0, nil }, // 0xFC
    { "", 0, nil }, // 0xFD
    { "", 0, nil }, // 0xFE
    { "", 0, nil }, // 0xFF
}

