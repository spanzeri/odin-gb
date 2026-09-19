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
    { "PREFIX",         1,  cpu_prefix_cb   }, // 0xCB
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

CpuPrefixInstructionInfo :: struct {
    disassembly:    string,
    procedure:      CpuInstructionProc,
}

CPU_CB_INSTRUCTIONS := [256]CpuPrefixInstructionInfo{
    { "RLC B",      cpu_rlc_b       }, // 0x00
    { "RLC C",      cpu_rlc_c       }, // 0x01
    { "RLC D",      cpu_rlc_d       }, // 0x02
    { "RLC E",      cpu_rlc_e       }, // 0x03
    { "RLC H",      cpu_rlc_h       }, // 0x04
    { "RLC L",      cpu_rlc_l       }, // 0x05
    { "RLC [HL]",   cpu_rlc_ptr_hl  }, // 0x06
    { "RLC A",      cpu_rlc_a       }, // 0x07
    { "RRC B",      cpu_rrc_b       }, // 0x08
    { "RRC C",      cpu_rrc_c       }, // 0x09
    { "RRC D",      cpu_rrc_d       }, // 0x0A
    { "RRC E",      cpu_rrc_e       }, // 0x0B
    { "RRC H",      cpu_rrc_h       }, // 0x0C
    { "RRC L",      cpu_rrc_l       }, // 0x0D
    { "RRC [HL]",   cpu_rrc_ptr_hl  }, // 0x0E
    { "RRC A",      cpu_rrc_a       }, // 0x0F
    { "RL B",       cpu_rl_b        }, // 0x10
    { "RL C",       cpu_rl_c        }, // 0x11
    { "RL D",       cpu_rl_d        }, // 0x12
    { "RL E",       cpu_rl_e        }, // 0x13
    { "RL H",       cpu_rl_h        }, // 0x14
    { "RL L",       cpu_rl_l        }, // 0x15
    { "RL [HL]",    cpu_rl_ptr_hl   }, // 0x16
    { "RL A",       cpu_rl_a        }, // 0x17
    { "RR B",       cpu_rr_b        }, // 0x18
    { "RR C",       cpu_rr_c        }, // 0x19
    { "RR D",       cpu_rr_d        }, // 0x1A
    { "RR E",       cpu_rr_e        }, // 0x1B
    { "RR H",       cpu_rr_h        }, // 0x1C
    { "RR L",       cpu_rr_l        }, // 0x1D
    { "RR [HL]",    cpu_rr_ptr_hl   }, // 0x1E
    { "RR A",       cpu_rr_a        }, // 0x1F
    { "SLA B",      cpu_sla_b       }, // 0x20
    { "SLA C",      cpu_sla_c       }, // 0x21
    { "SLA D",      cpu_sla_d       }, // 0x22
    { "SLA E",      cpu_sla_e       }, // 0x23
    { "SLA H",      cpu_sla_h       }, // 0x24
    { "SLA L",      cpu_sla_l       }, // 0x25
    { "SLA [HL]",   cpu_sla_ptr_hl  }, // 0x26
    { "SLA A",      cpu_sla_a       }, // 0x27
    { "SRA B",      cpu_sra_b       }, // 0x28
    { "SRA C",      cpu_sra_c       }, // 0x29
    { "SRA D",      cpu_sra_d       }, // 0x2A
    { "SRA E",      cpu_sra_e       }, // 0x2B
    { "SRA H",      cpu_sra_h       }, // 0x2C
    { "SRA L",      cpu_sra_l       }, // 0x2D
    { "SRA [HL]",   cpu_sra_ptr_hl  }, // 0x2E
    { "SRA A",      cpu_sra_a       }, // 0x2F
    { "SWAP B",     cpu_swap_b      }, // 0x30
    { "SWAP C",     cpu_swap_c      }, // 0x31
    { "SWAP D",     cpu_swap_d      }, // 0x32
    { "SWAP E",     cpu_swap_e      }, // 0x33
    { "SWAP H",     cpu_swap_h      }, // 0x34
    { "SWAP L",     cpu_swap_l      }, // 0x35
    { "SWAP [HL]",  cpu_swap_ptr_hl }, // 0x36
    { "SWAP A",     cpu_swap_a      }, // 0x37
    { "SRL B",      cpu_srl_b       }, // 0x38
    { "SRL C",      cpu_srl_c       }, // 0x39
    { "SRL D",      cpu_srl_d       }, // 0x3A
    { "SRL E",      cpu_srl_e       }, // 0x3B
    { "SRL H",      cpu_srl_h       }, // 0x3C
    { "SRL L",      cpu_srl_l       }, // 0x3D
    { "SRL [HL]",   cpu_srl_ptr_hl  }, // 0x3E
    { "SRL A",      cpu_srl_a       }, // 0x3F
    { "BIT 0 B",    cpu_bit_0_b     }, // 0x40
    { "BIT 0 C",    cpu_bit_0_c     }, // 0x41
    { "BIT 0 D",    cpu_bit_0_d     }, // 0x42
    { "BIT 0 E",    cpu_bit_0_e     }, // 0x43
    { "BIT 0 H",    cpu_bit_0_h     }, // 0x44
    { "BIT 0 L",    cpu_bit_0_l     }, // 0x45
    { "BIT 0 [HL]", cpu_bit_0_ptr_hl}, // 0x46
    { "BIT 0 A",    cpu_bit_0_a     }, // 0x47
    { "BIT 1 B",    cpu_bit_1_b     }, // 0x48
    { "BIT 1 C",    cpu_bit_1_c     }, // 0x49
    { "BIT 1 D",    cpu_bit_1_d     }, // 0x4A
    { "BIT 1 E",    cpu_bit_1_e     }, // 0x4B
    { "BIT 1 H",    cpu_bit_1_h     }, // 0x4C
    { "BIT 1 L",    cpu_bit_1_l     }, // 0x4D
    { "BIT 1 [HL]", cpu_bit_1_ptr_hl}, // 0x4E
    { "BIT 1 A",    cpu_bit_1_a     }, // 0x4F
    { "BIT 2 B",    cpu_bit_2_b     }, // 0x50
    { "BIT 2 C",    cpu_bit_2_c     }, // 0x51
    { "BIT 2 D",    cpu_bit_2_d     }, // 0x52
    { "BIT 2 E",    cpu_bit_2_e     }, // 0x53
    { "BIT 2 H",    cpu_bit_2_h     }, // 0x54
    { "BIT 2 L",    cpu_bit_2_l     }, // 0x55
    { "BIT 2 [HL]", cpu_bit_2_ptr_hl}, // 0x56
    { "BIT 2 A",    cpu_bit_2_a     }, // 0x57
    { "BIT 3 B",    cpu_bit_3_b     }, // 0x58
    { "BIT 3 C",    cpu_bit_3_c     }, // 0x59
    { "BIT 3 D",    cpu_bit_3_d     }, // 0x5A
    { "BIT 3 E",    cpu_bit_3_e     }, // 0x5B
    { "BIT 3 H",    cpu_bit_3_h     }, // 0x5C
    { "BIT 3 L",    cpu_bit_3_l     }, // 0x5D
    { "BIT 3 [HL]", cpu_bit_3_ptr_hl}, // 0x5E
    { "BIT 3 A",    cpu_bit_3_a     }, // 0x5F
    { "BIT 4 B",    cpu_bit_4_b     }, // 0x60
    { "BIT 4 C",    cpu_bit_4_c     }, // 0x61
    { "BIT 4 D",    cpu_bit_4_d     }, // 0x62
    { "BIT 4 E",    cpu_bit_4_e     }, // 0x63
    { "BIT 4 H",    cpu_bit_4_h     }, // 0x64
    { "BIT 4 L",    cpu_bit_4_l     }, // 0x65
    { "BIT 4 [HL]", cpu_bit_4_ptr_hl}, // 0x66
    { "BIT 4 A",    cpu_bit_4_a     }, // 0x67
    { "BIT 5 B",    cpu_bit_5_b     }, // 0x68
    { "BIT 5 C",    cpu_bit_5_c     }, // 0x69
    { "BIT 5 D",    cpu_bit_5_d     }, // 0x6A
    { "BIT 5 E",    cpu_bit_5_e     }, // 0x6B
    { "BIT 5 H",    cpu_bit_5_h     }, // 0x6C
    { "BIT 5 L",    cpu_bit_5_l     }, // 0x6D
    { "BIT 5 [HL]", cpu_bit_5_ptr_hl}, // 0x6E
    { "BIT 5 A",    cpu_bit_5_a     }, // 0x6F
    { "BIT 6 B",    cpu_bit_6_b     }, // 0x70
    { "BIT 6 C",    cpu_bit_6_c     }, // 0x71
    { "BIT 6 D",    cpu_bit_6_d     }, // 0x72
    { "BIT 6 E",    cpu_bit_6_e     }, // 0x73
    { "BIT 6 H",    cpu_bit_6_h     }, // 0x74
    { "BIT 6 L",    cpu_bit_6_l     }, // 0x75
    { "BIT 6 [HL]", cpu_bit_6_ptr_hl}, // 0x76
    { "BIT 6 A",    cpu_bit_6_a     }, // 0x77
    { "BIT 7 B",    cpu_bit_7_b     }, // 0x78
    { "BIT 7 C",    cpu_bit_7_c     }, // 0x79
    { "BIT 7 D",    cpu_bit_7_d     }, // 0x7A
    { "BIT 7 E",    cpu_bit_7_e     }, // 0x7B
    { "BIT 7 H",    cpu_bit_7_h     }, // 0x7C
    { "BIT 7 L",    cpu_bit_7_l     }, // 0x7D
    { "BIT 7 [HL]", cpu_bit_7_ptr_hl}, // 0x7E
    { "BIT 7 A",    cpu_bit_7_a     }, // 0x7F
    { "RES 0 B",    cpu_res_0_b     }, // 0x80
    { "RES 0 C",    cpu_res_0_c     }, // 0x81
    { "RES 0 D",    cpu_res_0_d     }, // 0x82
    { "RES 0 E",    cpu_res_0_e     }, // 0x83
    { "RES 0 H",    cpu_res_0_h     }, // 0x84
    { "RES 0 L",    cpu_res_0_l     }, // 0x85
    { "RES 0 [HL]", cpu_res_0_ptr_hl}, // 0x86
    { "RES 0 A",    cpu_res_0_a     }, // 0x87
    { "RES 1 B",    cpu_res_1_b     }, // 0x88
    { "RES 1 C",    cpu_res_1_c     }, // 0x89
    { "RES 1 D",    cpu_res_1_d     }, // 0x8A
    { "RES 1 E",    cpu_res_1_e     }, // 0x8B
    { "RES 1 H",    cpu_res_1_h     }, // 0x8C
    { "RES 1 L",    cpu_res_1_l     }, // 0x8D
    { "RES 1 [HL]", cpu_res_1_ptr_hl}, // 0x8E
    { "RES 1 A",    cpu_res_1_a     }, // 0x8F
    { "RES 2 B",    cpu_res_2_b     }, // 0x90
    { "RES 2 C",    cpu_res_2_c     }, // 0x91
    { "RES 2 D",    cpu_res_2_d     }, // 0x92
    { "RES 2 E",    cpu_res_2_e     }, // 0x93
    { "RES 2 H",    cpu_res_2_h     }, // 0x94
    { "RES 2 L",    cpu_res_2_l     }, // 0x95
    { "RES 2 [HL]", cpu_res_2_ptr_hl}, // 0x96
    { "RES 2 A",    cpu_res_2_a     }, // 0x97
    { "RES 3 B",    cpu_res_3_b     }, // 0x98
    { "RES 3 C",    cpu_res_3_c     }, // 0x99
    { "RES 3 D",    cpu_res_3_d     }, // 0x9A
    { "RES 3 E",    cpu_res_3_e     }, // 0x9B
    { "RES 3 H",    cpu_res_3_h     }, // 0x9C
    { "RES 3 L",    cpu_res_3_l     }, // 0x9D
    { "RES 3 [HL]", cpu_res_3_ptr_hl}, // 0x9E
    { "RES 3 A",    cpu_res_3_a     }, // 0x9F
    { "RES 4 B",    cpu_res_4_b     }, // 0xA0
    { "RES 4 C",    cpu_res_4_c     }, // 0xA1
    { "RES 4 D",    cpu_res_4_d     }, // 0xA2
    { "RES 4 E",    cpu_res_4_e     }, // 0xA3
    { "RES 4 H",    cpu_res_4_h     }, // 0xA4
    { "RES 4 L",    cpu_res_4_l     }, // 0xA5
    { "RES 4 [HL]", cpu_res_4_ptr_hl}, // 0xA6
    { "RES 4 A",    cpu_res_4_a     }, // 0xA7
    { "RES 5 B",    cpu_res_5_b     }, // 0xA8
    { "RES 5 C",    cpu_res_5_c     }, // 0xA9
    { "RES 5 D",    cpu_res_5_d     }, // 0xAA
    { "RES 5 E",    cpu_res_5_e     }, // 0xAB
    { "RES 5 H",    cpu_res_5_h     }, // 0xAC
    { "RES 5 L",    cpu_res_5_l     }, // 0xAD
    { "RES 5 [HL]", cpu_res_5_ptr_hl}, // 0xAE
    { "RES 5 A",    cpu_res_5_a     }, // 0xAF
    { "RES 6 B",    cpu_res_6_b     }, // 0xB0
    { "RES 6 C",    cpu_res_6_c     }, // 0xB1
    { "RES 6 D",    cpu_res_6_d     }, // 0xB2
    { "RES 6 E",    cpu_res_6_e     }, // 0xB3
    { "RES 6 H",    cpu_res_6_h     }, // 0xB4
    { "RES 6 L",    cpu_res_6_l     }, // 0xB5
    { "RES 6 [HL]", cpu_res_6_ptr_hl}, // 0xB6
    { "RES 6 A",    cpu_res_6_a     }, // 0xB7
    { "RES 7 B",    cpu_res_7_b     }, // 0xB8
    { "RES 7 C",    cpu_res_7_c     }, // 0xB9
    { "RES 7 D",    cpu_res_7_d     }, // 0xBA
    { "RES 7 E",    cpu_res_7_e     }, // 0xBB
    { "RES 7 H",    cpu_res_7_h     }, // 0xBC
    { "RES 7 L",    cpu_res_7_l     }, // 0xBD
    { "RES 7 [HL]", cpu_res_7_ptr_hl}, // 0xBE
    { "RES 7 A",    cpu_res_7_a     }, // 0xBF
    { "SET 0 B",    cpu_set_0_b     }, // 0xC0
    { "SET 0 C",    cpu_set_0_c     }, // 0xC1
    { "SET 0 D",    cpu_set_0_d     }, // 0xC2
    { "SET 0 E",    cpu_set_0_e     }, // 0xC3
    { "SET 0 H",    cpu_set_0_h     }, // 0xC4
    { "SET 0 L",    cpu_set_0_l     }, // 0xC5
    { "SET 0 [HL]", cpu_set_0_ptr_hl}, // 0xC6
    { "SET 0 A",    cpu_set_0_a     }, // 0xC7
    { "SET 1 B",    cpu_set_1_b     }, // 0xC8
    { "SET 1 C",    cpu_set_1_c     }, // 0xC9
    { "SET 1 D",    cpu_set_1_d     }, // 0xCA
    { "SET 1 E",    cpu_set_1_e     }, // 0xCB
    { "SET 1 H",    cpu_set_1_h     }, // 0xCC
    { "SET 1 L",    cpu_set_1_l     }, // 0xCD
    { "SET 1 [HL]", cpu_set_1_ptr_hl}, // 0xCE
    { "SET 1 A",    cpu_set_1_a     }, // 0xCF
    { "SET 2 B",    cpu_set_2_b     }, // 0xD0
    { "SET 2 C",    cpu_set_2_c     }, // 0xD1
    { "SET 2 D",    cpu_set_2_d     }, // 0xD2
    { "SET 2 E",    cpu_set_2_e     }, // 0xD3
    { "SET 2 H",    cpu_set_2_h     }, // 0xD4
    { "SET 2 L",    cpu_set_2_l     }, // 0xD5
    { "SET 2 [HL]", cpu_set_2_ptr_hl}, // 0xD6
    { "SET 2 A",    cpu_set_2_a     }, // 0xD7
    { "SET 3 B",    cpu_set_3_b     }, // 0xD8
    { "SET 3 C",    cpu_set_3_c     }, // 0xD9
    { "SET 3 D",    cpu_set_3_d     }, // 0xDA
    { "SET 3 E",    cpu_set_3_e     }, // 0xDB
    { "SET 3 H",    cpu_set_3_h     }, // 0xDC
    { "SET 3 L",    cpu_set_3_l     }, // 0xDD
    { "SET 3 [HL]", cpu_set_3_ptr_hl}, // 0xDE
    { "SET 3 A",    cpu_set_3_a     }, // 0xDF
    { "SET 4 B",    cpu_set_4_b     }, // 0xE0
    { "SET 4 C",    cpu_set_4_c     }, // 0xE1
    { "SET 4 D",    cpu_set_4_d     }, // 0xE2
    { "SET 4 E",    cpu_set_4_e     }, // 0xE3
    { "SET 4 H",    cpu_set_4_h     }, // 0xE4
    { "SET 4 L",    cpu_set_4_l     }, // 0xE5
    { "SET 4 [HL]", cpu_set_4_ptr_hl}, // 0xE6
    { "SET 4 A",    cpu_set_4_a     }, // 0xE7
    { "SET 5 B",    cpu_set_5_b     }, // 0xE8
    { "SET 5 C",    cpu_set_5_c     }, // 0xE9
    { "SET 5 D",    cpu_set_5_d     }, // 0xEA
    { "SET 5 E",    cpu_set_5_e     }, // 0xEB
    { "SET 5 H",    cpu_set_5_h     }, // 0xEC
    { "SET 5 L",    cpu_set_5_l     }, // 0xED
    { "SET 5 [HL]", cpu_set_5_ptr_hl}, // 0xEE
    { "SET 5 A",    cpu_set_5_a     }, // 0xEF
    { "SET 6 B",    cpu_set_6_b     }, // 0xF0
    { "SET 6 C",    cpu_set_6_c     }, // 0xF1
    { "SET 6 D",    cpu_set_6_d     }, // 0xF2
    { "SET 6 E",    cpu_set_6_e     }, // 0xF3
    { "SET 6 H",    cpu_set_6_h     }, // 0xF4
    { "SET 6 L",    cpu_set_6_l     }, // 0xF5
    { "SET 6 [HL]", cpu_set_6_ptr_hl}, // 0xF6
    { "SET 6 A",    cpu_set_6_a     }, // 0xF7
    { "SET 7 B",    cpu_set_7_b     }, // 0xF8
    { "SET 7 C",    cpu_set_7_c     }, // 0xF9
    { "SET 7 D",    cpu_set_7_d     }, // 0xFA
    { "SET 7 E",    cpu_set_7_e     }, // 0xFB
    { "SET 7 H",    cpu_set_7_h     }, // 0xFC
    { "SET 7 L",    cpu_set_7_l     }, // 0xFD
    { "SET 7 [HL]", cpu_set_7_ptr_hl}, // 0xFE
    { "SET 7 A",    cpu_set_7_a     }, // 0xFF
}

