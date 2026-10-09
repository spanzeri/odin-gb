package odin_gb

import "core:log"

cpu_debug_instructions := false

CpuRunState :: enum {
    Running,
    Halted,
    Stopped,
}

cpu_run_state := CpuRunState.Running

CpuRegisters :: struct {
    using _: struct #raw_union {
        af: u16,
        using _: struct {
            f, a: u8,
        }
    },

    using _: struct #raw_union {
        bc: u16,
        using _: struct {
            c, b: u8,
        }
    },

    using _: struct #raw_union {
        de: u16,
        using _: struct {
            e, d: u8,
        }
    },

    using _: struct #raw_union {
        hl: u16,
        using _: struct {
            l, h: u8,
        }
    },

    using _: struct #raw_union {
        sp: u16,
        using _: struct {
            p, s: u8,
        }
    },

    pc: u16,
}

CpuFlag :: enum {
    Z = 1 << 7,
    N = 1 << 6,
    H = 1 << 5,
    C = 1 << 4,
}

cpu_registers: CpuRegisters

cpu_tick :: proc () {
    if cpu_run_state == .Stopped {
        if cpu_stop_wake_requested {
            cpu_stop_wake_requested = false
            cpu_run_state = .Running
            interrupt_service_routine()
        }
        return
    }

    if cpu_run_state == .Running {
        cpu_fetch()
        cpu_execute()
        instruction_counter += 1

        if interrupt_enable_ime_delay > 0 {
            interrupt_enable_ime_delay -= 1
            if interrupt_enable_ime_delay == 0 {
                interrupt_master_enabled = true
            }
        }
    } else {
        core_advance_cpu_clocks(4)
    }

    if instruction_counter == 10_000 && cpu_debug_instructions {
        cpu_debug_instructions = false
        debug_log_close()
    }

    interrupt_service_routine()
}

cpu_execute_halt_bug :: proc () {
    if cpu_halt_bug {
        cpu_halt_bug = false
        cpu_registers.pc -= 1
    }
}

@(private="file")
cpu_fetch :: proc () {
    if cpu_debug_instructions {
        cpu_dump_registers()
    }

    current_op_code = memory_bus_read(cpu_registers.pc)
    cpu_registers.pc += 1
    core_advance_cpu_clocks(4)                   // complete M1: opcode fetch
    instruction := CPU_INSTRUCTIONS[current_op_code]
    current_instruction_proc = instruction.procedure

    cpu_execute_halt_bug()
}

@(private="file")
cpu_execute :: proc () -> bool {
    if current_instruction_proc != nil {
        current_instruction_proc()
        return true
    }

    instruction := CPU_INSTRUCTIONS[current_op_code]
    pchi := ((cpu_registers.pc - 1) & 0xFF00) >> 8
    pclo := ((cpu_registers.pc - 1) & 0xFF)
    log.errorf(
        "Unknown instruction |{:02X}| at: {:02X}{:02X} ({}), count {}",
        current_op_code,
        pchi,
        pclo,
        instruction.disassembly,
        instruction_counter,
    )

    return false
}

cpu_reset :: proc () {
    // @TODO: At some point maybe execute the boot ROM. However, for now set to
    // known values.
    cpu_registers.af = 0x01B0
    cpu_registers.bc = 0x0013
    cpu_registers.de = 0x00D8
    cpu_registers.hl = 0x014D
    cpu_registers.sp = 0xFFFE
    cpu_registers.pc = 0x0100
}

@(private="file")
cpu_dump_registers :: proc () {
    opcode := memory_bus_read(cpu_registers.pc)
    instruction := CPU_INSTRUCTIONS[opcode]
    pchi := (cpu_registers.pc & 0xFF00) >> 8
    pclo := (cpu_registers.pc & 0x00FF)
    sphi := (cpu_registers.sp & 0xFF00) >> 8
    splo := (cpu_registers.sp & 0x00FF)

    if instruction.operand_length == 0 {
        debug_log(
            "AF: {:02X}{:02X} BC: {:02X}{:02X} DE: {:02X}{:02X} HL: {:02X}{:02X} SP: {:02X}{:02X} PC: {:02X}{:02X} {}",
            cpu_registers.a, cpu_registers.f,
            cpu_registers.b, cpu_registers.c,
            cpu_registers.d, cpu_registers.e,
            cpu_registers.h, cpu_registers.l,
            sphi, splo,
            pchi, pclo,
            instruction.disassembly,
        )
    } else if instruction.operand_length == 1 {
        operand := memory_bus_read(cpu_registers.pc + 1)
        debug_log(
            "AF: {:02X}{:02X} BC: {:02X}{:02X} DE: {:02X}{:02X} HL: {:02X}{:02X} SP: {:02X}{:02X} PC: {:02X}{:02X} {} ({:02X})",
            cpu_registers.a, cpu_registers.f,
            cpu_registers.b, cpu_registers.c,
            cpu_registers.d, cpu_registers.e,
            cpu_registers.h, cpu_registers.l,
            sphi, splo,
            pchi, pclo,
            instruction.disassembly,
            operand,
        )
    } else if instruction.operand_length == 2 {
        oplo := memory_bus_read(cpu_registers.pc + 1)
        ophi := memory_bus_read(cpu_registers.pc + 2)
        debug_log(
            "AF: {:02X}{:02X} BC: {:02X}{:02X} DE: {:02X}{:02X} HL: {:02X}{:02X} SP: {:02X}{:02X} PC: {:02X}{:02X} {} ({:02X}{:02X})",
            cpu_registers.a, cpu_registers.f,
            cpu_registers.b, cpu_registers.c,
            cpu_registers.d, cpu_registers.e,
            cpu_registers.h, cpu_registers.l,
            sphi, splo,
            pchi, pclo,
            instruction.disassembly,
            ophi, oplo,
        )
    }
}

@(private="file")
current_op_code: u8

@(private="file")
instruction_counter: i64

@(private="file")
current_instruction_proc: CpuInstructionProc

cpu_halt_bug := false

cpu_noop :: proc ()  {}

cpu_jp_a16 :: proc ()  {
    temp :u16= cast(u16)memory_bus_read(cpu_registers.pc)
    cpu_registers.pc += 1
    core_advance_cpu_clocks(4)

    temp |= cast(u16)memory_bus_read(cpu_registers.pc) << 8
    cpu_registers.pc += 1
    core_advance_cpu_clocks(4)

    cpu_registers.pc = temp
    core_advance_cpu_clocks(4)
}

cpu_halt :: proc () {
    is_interrupt_pending := (interrupt_pending() != 0)
    if !interrupt_master_enabled && is_interrupt_pending {
        cpu_halt_bug = true
    } else {
        cpu_run_state = .Halted
    }
}

cpu_inc_b :: proc () { inc_r8(&cpu_registers.b) }
cpu_inc_c :: proc () { inc_r8(&cpu_registers.c) }
cpu_inc_d :: proc () { inc_r8(&cpu_registers.d) }
cpu_inc_e :: proc () { inc_r8(&cpu_registers.e) }
cpu_inc_h :: proc () { inc_r8(&cpu_registers.h) }
cpu_inc_l :: proc () { inc_r8(&cpu_registers.l) }
cpu_inc_a :: proc () { inc_r8(&cpu_registers.a) }

cpu_dec_b :: proc () { dec_r8(&cpu_registers.b) }
cpu_dec_c :: proc () { dec_r8(&cpu_registers.c) }
cpu_dec_d :: proc () { dec_r8(&cpu_registers.d) }
cpu_dec_e :: proc () { dec_r8(&cpu_registers.e) }
cpu_dec_h :: proc () { dec_r8(&cpu_registers.h) }
cpu_dec_l :: proc () { dec_r8(&cpu_registers.l) }
cpu_dec_a :: proc () { dec_r8(&cpu_registers.a) }

cpu_inc_bc :: proc () { inc_r16(&cpu_registers.bc) }
cpu_inc_de :: proc () { inc_r16(&cpu_registers.de) }
cpu_inc_hl :: proc () { inc_r16(&cpu_registers.hl) }
cpu_inc_sp :: proc () { inc_r16(&cpu_registers.sp) }

cpu_dec_bc :: proc () { dec_r16(&cpu_registers.bc) }
cpu_dec_de :: proc () { dec_r16(&cpu_registers.de) }
cpu_dec_hl :: proc () { dec_r16(&cpu_registers.hl) }
cpu_dec_sp :: proc () { dec_r16(&cpu_registers.sp) }

cpu_add_hl_bc :: proc () { add_hl_16(cpu_registers.bc) }
cpu_add_hl_de :: proc () { add_hl_16(cpu_registers.de) }
cpu_add_hl_hl :: proc () { add_hl_16(cpu_registers.hl) }
cpu_add_hl_sp :: proc () { add_hl_16(cpu_registers.sp) }

cpu_add_b :: proc () { add_to_a(cpu_registers.b) }
cpu_add_c :: proc () { add_to_a(cpu_registers.c) }
cpu_add_d :: proc () { add_to_a(cpu_registers.d) }
cpu_add_e :: proc () { add_to_a(cpu_registers.e) }
cpu_add_h :: proc () { add_to_a(cpu_registers.h) }
cpu_add_l :: proc () { add_to_a(cpu_registers.l) }
cpu_add_a :: proc () { add_to_a(cpu_registers.a) }

cpu_add_ptr_hl :: proc () {
    z := memory_bus_read(cpu_registers.hl)
    core_advance_cpu_clocks(4)
    add_to_a(z)
}

cpu_add_n8 :: proc () {
    z := memory_bus_read(cpu_registers.pc); cpu_registers.pc += 1
    core_advance_cpu_clocks(4)
    add_to_a(z)
}

cpu_add_sp :: proc () {
    z := cast(i8)memory_bus_read(cpu_registers.pc); cpu_registers.pc += 1
    core_advance_cpu_clocks(4)

    set_flag(.Z, 0)
    set_flag(.N, 0)
    e := cast(u8)z
    set_flag(.C, (cpu_registers.sp & 0x00FF) + cast(u16)e > 0x00FF)
    set_flag(.H, (cpu_registers.sp & 0x0F) + cast(u16)(e & 0x0F) > 0x0F)
    core_advance_cpu_clocks(4)

    temp := cast(u16)(cast(i32)z + cast(i32)cpu_registers.sp)
    core_advance_cpu_clocks(4)

    cpu_registers.sp = temp
}

cpu_adc_ptr_hl :: proc () {
    z := memory_bus_read(cpu_registers.hl)
    core_advance_cpu_clocks(4)
    adc_to_a(z)
}

cpu_adc_n8 :: proc () {
    z := memory_bus_read(cpu_registers.pc); cpu_registers.pc += 1
    core_advance_cpu_clocks(4)
    adc_to_a(z)
}

cpu_adc_b :: proc () { adc_to_a(cpu_registers.b) }
cpu_adc_c :: proc () { adc_to_a(cpu_registers.c) }
cpu_adc_d :: proc () { adc_to_a(cpu_registers.d) }
cpu_adc_e :: proc () { adc_to_a(cpu_registers.e) }
cpu_adc_h :: proc () { adc_to_a(cpu_registers.h) }
cpu_adc_l :: proc () { adc_to_a(cpu_registers.l) }
cpu_adc_a :: proc () { adc_to_a(cpu_registers.a) }

cpu_sub_b :: proc () { sub_to_a(cpu_registers.b) }
cpu_sub_c :: proc () { sub_to_a(cpu_registers.c) }
cpu_sub_d :: proc () { sub_to_a(cpu_registers.d) }
cpu_sub_e :: proc () { sub_to_a(cpu_registers.e) }
cpu_sub_h :: proc () { sub_to_a(cpu_registers.h) }
cpu_sub_l :: proc () { sub_to_a(cpu_registers.l) }
cpu_sub_a :: proc () { sub_to_a(cpu_registers.a) }

cpu_sbc_b :: proc () { sbc_to_a(cpu_registers.b) }
cpu_sbc_c :: proc () { sbc_to_a(cpu_registers.c) }
cpu_sbc_d :: proc () { sbc_to_a(cpu_registers.d) }
cpu_sbc_e :: proc () { sbc_to_a(cpu_registers.e) }
cpu_sbc_h :: proc () { sbc_to_a(cpu_registers.h) }
cpu_sbc_l :: proc () { sbc_to_a(cpu_registers.l) }
cpu_sbc_a :: proc () { sbc_to_a(cpu_registers.a) }

cpu_sub_ptr_hl :: proc () {
    z := memory_bus_read(cpu_registers.hl)
    core_advance_cpu_clocks(4)
    sub_to_a(z)
}

cpu_sub_n8 :: proc () {
    z := memory_bus_read(cpu_registers.pc); cpu_registers.pc += 1
    core_advance_cpu_clocks(4)
    sub_to_a(z)
}

cpu_sbc_ptr_hl :: proc () {
    z := memory_bus_read(cpu_registers.hl)
    core_advance_cpu_clocks(4)
    sbc_to_a(z)
}

cpu_sbc_n8 :: proc () {
    z := memory_bus_read(cpu_registers.pc); cpu_registers.pc += 1
    core_advance_cpu_clocks(4)
    sbc_to_a(z)
}

cpu_and_b :: proc () { and_with_a(cpu_registers.b) }
cpu_and_c :: proc () { and_with_a(cpu_registers.c) }
cpu_and_d :: proc () { and_with_a(cpu_registers.d) }
cpu_and_e :: proc () { and_with_a(cpu_registers.e) }
cpu_and_h :: proc () { and_with_a(cpu_registers.h) }
cpu_and_l :: proc () { and_with_a(cpu_registers.l) }
cpu_and_a :: proc () { and_with_a(cpu_registers.a) }

cpu_and_ptr_hl :: proc () {
    z := memory_bus_read(cpu_registers.hl)
    core_advance_cpu_clocks(4)
    and_with_a(z)
}

cpu_and_n8 :: proc() {
    z := memory_bus_read(cpu_registers.pc); cpu_registers.pc += 1
    core_advance_cpu_clocks(4)
    and_with_a(z)
}

cpu_xor_b :: proc () { xor_with_a(cpu_registers.b) }
cpu_xor_c :: proc () { xor_with_a(cpu_registers.c) }
cpu_xor_d :: proc () { xor_with_a(cpu_registers.d) }
cpu_xor_e :: proc () { xor_with_a(cpu_registers.e) }
cpu_xor_h :: proc () { xor_with_a(cpu_registers.h) }
cpu_xor_l :: proc () { xor_with_a(cpu_registers.l) }
cpu_xor_a :: proc () { xor_with_a(cpu_registers.a) }

cpu_xor_ptr_hl :: proc () {
    z := memory_bus_read(cpu_registers.hl)
    core_advance_cpu_clocks(4)
    xor_with_a(z)
}

cpu_xor_n8 :: proc () {
    z := memory_bus_read(cpu_registers.pc); cpu_registers.pc += 1
    core_advance_cpu_clocks(4)
    xor_with_a(z)
}

cpu_or_b :: proc () { or_with_a(cpu_registers.b) }
cpu_or_c :: proc () { or_with_a(cpu_registers.c) }
cpu_or_d :: proc () { or_with_a(cpu_registers.d) }
cpu_or_e :: proc () { or_with_a(cpu_registers.e) }
cpu_or_h :: proc () { or_with_a(cpu_registers.h) }
cpu_or_l :: proc () { or_with_a(cpu_registers.l) }
cpu_or_a :: proc () { or_with_a(cpu_registers.a) }

cpu_or_ptr_hl :: proc () {
    z := memory_bus_read(cpu_registers.hl)
    core_advance_cpu_clocks(4)
    or_with_a(z)
}

cpu_or_n8 :: proc () {
    z := memory_bus_read(cpu_registers.pc); cpu_registers.pc += 1
    core_advance_cpu_clocks(4)
    or_with_a(z)
}

cpu_cp_b :: proc () { cp_with_a(cpu_registers.b) }
cpu_cp_c :: proc () { cp_with_a(cpu_registers.c) }
cpu_cp_d :: proc () { cp_with_a(cpu_registers.d) }
cpu_cp_e :: proc () { cp_with_a(cpu_registers.e) }
cpu_cp_h :: proc () { cp_with_a(cpu_registers.h) }
cpu_cp_l :: proc () { cp_with_a(cpu_registers.l) }
cpu_cp_a :: proc () { cp_with_a(cpu_registers.a) }

cpu_cp_ptr_hl :: proc () {
    z := memory_bus_read(cpu_registers.hl)
    core_advance_cpu_clocks(4)
    cp_with_a(z)
}

cpu_cp_n8 :: proc () {
    z := memory_bus_read(cpu_registers.pc); cpu_registers.pc += 1
    core_advance_cpu_clocks(4)
    cp_with_a(z)
}

cpu_ld_b_b :: proc () { cpu_registers.b = cpu_registers.b }
cpu_ld_b_c :: proc () { cpu_registers.b = cpu_registers.c }
cpu_ld_b_d :: proc () { cpu_registers.b = cpu_registers.d }
cpu_ld_b_e :: proc () { cpu_registers.b = cpu_registers.e }
cpu_ld_b_h :: proc () { cpu_registers.b = cpu_registers.h }
cpu_ld_b_l :: proc () { cpu_registers.b = cpu_registers.l }
cpu_ld_b_a :: proc () { cpu_registers.b = cpu_registers.a }
cpu_ld_c_b :: proc () { cpu_registers.c = cpu_registers.b }
cpu_ld_c_c :: proc () { cpu_registers.c = cpu_registers.c }
cpu_ld_c_d :: proc () { cpu_registers.c = cpu_registers.d }
cpu_ld_c_e :: proc () { cpu_registers.c = cpu_registers.e }
cpu_ld_c_h :: proc () { cpu_registers.c = cpu_registers.h }
cpu_ld_c_l :: proc () { cpu_registers.c = cpu_registers.l }
cpu_ld_c_a :: proc () { cpu_registers.c = cpu_registers.a }
cpu_ld_d_b :: proc () { cpu_registers.d = cpu_registers.b }
cpu_ld_d_c :: proc () { cpu_registers.d = cpu_registers.c }
cpu_ld_d_d :: proc () { cpu_registers.d = cpu_registers.d }
cpu_ld_d_e :: proc () { cpu_registers.d = cpu_registers.e }
cpu_ld_d_h :: proc () { cpu_registers.d = cpu_registers.h }
cpu_ld_d_l :: proc () { cpu_registers.d = cpu_registers.l }
cpu_ld_d_a :: proc () { cpu_registers.d = cpu_registers.a }
cpu_ld_e_b :: proc () { cpu_registers.e = cpu_registers.b }
cpu_ld_e_c :: proc () { cpu_registers.e = cpu_registers.c }
cpu_ld_e_d :: proc () { cpu_registers.e = cpu_registers.d }
cpu_ld_e_e :: proc () { cpu_registers.e = cpu_registers.e }
cpu_ld_e_h :: proc () { cpu_registers.e = cpu_registers.h }
cpu_ld_e_l :: proc () { cpu_registers.e = cpu_registers.l }
cpu_ld_e_a :: proc () { cpu_registers.e = cpu_registers.a }
cpu_ld_h_b :: proc () { cpu_registers.h = cpu_registers.b }
cpu_ld_h_c :: proc () { cpu_registers.h = cpu_registers.c }
cpu_ld_h_d :: proc () { cpu_registers.h = cpu_registers.d }
cpu_ld_h_e :: proc () { cpu_registers.h = cpu_registers.e }
cpu_ld_h_h :: proc () { cpu_registers.h = cpu_registers.h }
cpu_ld_h_l :: proc () { cpu_registers.h = cpu_registers.l }
cpu_ld_h_a :: proc () { cpu_registers.h = cpu_registers.a }
cpu_ld_l_b :: proc () { cpu_registers.l = cpu_registers.b }
cpu_ld_l_c :: proc () { cpu_registers.l = cpu_registers.c }
cpu_ld_l_d :: proc () { cpu_registers.l = cpu_registers.d }
cpu_ld_l_e :: proc () { cpu_registers.l = cpu_registers.e }
cpu_ld_l_h :: proc () { cpu_registers.l = cpu_registers.h }
cpu_ld_l_l :: proc () { cpu_registers.l = cpu_registers.l }
cpu_ld_l_a :: proc () { cpu_registers.l = cpu_registers.a }
cpu_ld_a_b :: proc () { cpu_registers.a = cpu_registers.b }
cpu_ld_a_c :: proc () { cpu_registers.a = cpu_registers.c }
cpu_ld_a_d :: proc () { cpu_registers.a = cpu_registers.d }
cpu_ld_a_e :: proc () { cpu_registers.a = cpu_registers.e }
cpu_ld_a_h :: proc () { cpu_registers.a = cpu_registers.h }
cpu_ld_a_l :: proc () { cpu_registers.a = cpu_registers.l }
cpu_ld_a_a :: proc () { cpu_registers.a = cpu_registers.a }

cpu_ld_b_n8 :: proc () { ld_8(&cpu_registers.b) }
cpu_ld_c_n8 :: proc () { ld_8(&cpu_registers.c) }
cpu_ld_d_n8 :: proc () { ld_8(&cpu_registers.d) }
cpu_ld_e_n8 :: proc () { ld_8(&cpu_registers.e) }
cpu_ld_h_n8 :: proc () { ld_8(&cpu_registers.h) }
cpu_ld_l_n8 :: proc () { ld_8(&cpu_registers.l) }
cpu_ld_a_n8 :: proc () { ld_8(&cpu_registers.a) }

cpu_ld_hl_dec_a :: proc () {
    memory_bus_write(cpu_registers.hl, cpu_registers.a)
    cpu_registers.hl -= 1
    core_advance_cpu_clocks(4)
}

cpu_ld_hl_inc_a :: proc () {
    memory_bus_write(cpu_registers.hl, cpu_registers.a)
    cpu_registers.hl += 1
    core_advance_cpu_clocks(4)
}

cpu_ldh_n8_a :: proc () {
    z := memory_bus_read(cpu_registers.pc); cpu_registers.pc += 1
    core_advance_cpu_clocks(4)

    memory_bus_write(0xFF00 | cast(u16)z, cpu_registers.a)
    core_advance_cpu_clocks(4)
}

cpu_ldh_c_a :: proc () {
    memory_bus_write(0xFF00 | cast(u16)cpu_registers.c, cpu_registers.a)
    core_advance_cpu_clocks(4)
}

cpu_ldh_a_n8 :: proc () {
    z := memory_bus_read(cpu_registers.pc); cpu_registers.pc += 1
    core_advance_cpu_clocks(4)
    w := memory_bus_read(0xFF00 | cast(u16)z)
    core_advance_cpu_clocks(4)
    cpu_registers.a = w
}

cpu_ldh_a_c :: proc () {
    w := memory_bus_read(0xFF00 | cast(u16)cpu_registers.c)
    core_advance_cpu_clocks(4)
    cpu_registers.a = w
}

cpu_ld_ptr_a :: proc () {
    z := memory_bus_read(cpu_registers.pc); cpu_registers.pc += 1
    core_advance_cpu_clocks(4)
    w := memory_bus_read(cpu_registers.pc); cpu_registers.pc += 1
    core_advance_cpu_clocks(4)
    memory_bus_write((cast(u16)w << 8) | cast(u16)z, cpu_registers.a)
    core_advance_cpu_clocks(4)
}

cpu_ld_hl_spe8 :: proc () {
    z := cast(i8)memory_bus_read(cpu_registers.pc); cpu_registers.pc += 1
    core_advance_cpu_clocks(4)

    set_flag(.Z, 0)
    set_flag(.N, 0)
    e := cast(u8)z
    set_flag(.C, (cpu_registers.sp & 0x00FF) + cast(u16)e > 0x00FF)
    set_flag(.H, (cpu_registers.sp & 0x0F) + cast(u16)(e & 0x0F) > 0x0F)
    core_advance_cpu_clocks(4)

    cpu_registers.hl = cast(u16)(cast(i32)z + cast(i32)cpu_registers.sp)
}

cpu_ld_sp_hl :: proc () {
    cpu_registers.sp = cpu_registers.hl
    core_advance_cpu_clocks(4)
}

cpu_ld_a_ptr :: proc () {
    z := memory_bus_read(cpu_registers.pc); cpu_registers.pc += 1
    core_advance_cpu_clocks(4)
    w := memory_bus_read(cpu_registers.pc); cpu_registers.pc += 1
    core_advance_cpu_clocks(4)
    temp := memory_bus_read((cast(u16)w << 8) | cast(u16)z)
    core_advance_cpu_clocks(4)
    cpu_registers.a = temp
}

cpu_inc_hl_ptr :: proc () {
    z := memory_bus_read(cpu_registers.hl)
    core_advance_cpu_clocks(4)

    result := z + 1
    memory_bus_write(cpu_registers.hl, result)
    set_flag(.Z, result == 0)
    set_flag(.N, 0)
    set_flag(.H, (z & 0x0F) == 0x0F)
    core_advance_cpu_clocks(4)
}

cpu_dec_hl_ptr :: proc () {
    z := memory_bus_read(cpu_registers.hl)
    core_advance_cpu_clocks(4)

    result := z - 1
    memory_bus_write(cpu_registers.hl, result)
    set_flag(.Z, result == 0)
    set_flag(.N, 1)
    set_flag(.H, (z & 0x0F) == 0x00)
    core_advance_cpu_clocks(4)
}

cpu_ld_hl_ptr_n8 :: proc () {
    z := memory_bus_read(cpu_registers.pc); cpu_registers.pc += 1
    core_advance_cpu_clocks(4)

    memory_bus_write(cpu_registers.hl, z)
    core_advance_cpu_clocks(4)
}

cpu_di :: proc () {
    interrupt_master_enabled = false
    interrupt_enable_ime_delay = 0
}

cpu_ei :: proc () {
    if !interrupt_master_enabled && interrupt_enable_ime_delay == 0 {
        interrupt_enable_ime_delay = 2
    }
}

cpu_scf :: proc () {
    set_flag(.N, 0)
    set_flag(.H, 0)
    set_flag(.C, 1)
}

cpu_ccf :: proc () {
    set_flag(.N, 0)
    set_flag(.H, 0)
    set_flag(.C, !get_flag(.C))
}

cpu_ld_bc_n16 :: proc ()  { ld_16(&cpu_registers.bc) }
cpu_ld_de_n16 :: proc ()  { ld_16(&cpu_registers.de) }
cpu_ld_hl_n16 :: proc ()  { ld_16(&cpu_registers.hl) }
cpu_ld_sp_n16 :: proc ()  { ld_16(&cpu_registers.sp) }

cpu_ld_bc_a :: proc () { ld_8_ptr(cpu_registers.bc, cpu_registers.a) }
cpu_ld_de_a :: proc () { ld_8_ptr(cpu_registers.de, cpu_registers.a) }
cpu_ld_hl_b :: proc () { ld_8_ptr(cpu_registers.hl, cpu_registers.b) }
cpu_ld_hl_c :: proc () { ld_8_ptr(cpu_registers.hl, cpu_registers.c) }
cpu_ld_hl_d :: proc () { ld_8_ptr(cpu_registers.hl, cpu_registers.d) }
cpu_ld_hl_e :: proc () { ld_8_ptr(cpu_registers.hl, cpu_registers.e) }
cpu_ld_hl_h :: proc () { ld_8_ptr(cpu_registers.hl, cpu_registers.h) }
cpu_ld_hl_l :: proc () { ld_8_ptr(cpu_registers.hl, cpu_registers.l) }
cpu_ld_hl_a :: proc () { ld_8_ptr(cpu_registers.hl, cpu_registers.a) }

cpu_ld_a_bc :: proc () { ld_r8_from_ptr(&cpu_registers.a, cpu_registers.bc) }
cpu_ld_a_de :: proc () { ld_r8_from_ptr(&cpu_registers.a, cpu_registers.de) }
cpu_ld_b_hl :: proc () { ld_r8_from_ptr(&cpu_registers.b, cpu_registers.hl) }
cpu_ld_c_hl :: proc () { ld_r8_from_ptr(&cpu_registers.c, cpu_registers.hl) }
cpu_ld_d_hl :: proc () { ld_r8_from_ptr(&cpu_registers.d, cpu_registers.hl) }
cpu_ld_e_hl :: proc () { ld_r8_from_ptr(&cpu_registers.e, cpu_registers.hl) }
cpu_ld_h_hl :: proc () { ld_r8_from_ptr(&cpu_registers.h, cpu_registers.hl) }
cpu_ld_l_hl :: proc () { ld_r8_from_ptr(&cpu_registers.l, cpu_registers.hl) }
cpu_ld_a_hl :: proc () { ld_r8_from_ptr(&cpu_registers.a, cpu_registers.hl) }

cpu_ld_a_hl_inc :: proc () {
    z := memory_bus_read(cpu_registers.hl); cpu_registers.hl += 1
    core_advance_cpu_clocks(4)

    cpu_registers.a = z
}

cpu_ld_a_hl_dec :: proc () {
    z := memory_bus_read(cpu_registers.hl); cpu_registers.hl -= 1
    core_advance_cpu_clocks(4)

    cpu_registers.a = z
}

cpu_rst_00 :: proc () { rst_nn(0x00) }
cpu_rst_08 :: proc () { rst_nn(0x08) }
cpu_rst_10 :: proc () { rst_nn(0x10) }
cpu_rst_18 :: proc () { rst_nn(0x18) }
cpu_rst_20 :: proc () { rst_nn(0x20) }
cpu_rst_28 :: proc () { rst_nn(0x28) }
cpu_rst_30 :: proc () { rst_nn(0x30) }
cpu_rst_38 :: proc () { rst_nn(0x38) }

cpu_push_bc :: proc () { push_16(cpu_registers.bc) }
cpu_push_de :: proc () { push_16(cpu_registers.de) }
cpu_push_hl :: proc () { push_16(cpu_registers.hl) }
cpu_push_af :: proc () { push_16(cpu_registers.af) }

cpu_pop_bc :: proc () { pop_16(&cpu_registers.bc) }
cpu_pop_de :: proc () { pop_16(&cpu_registers.de) }
cpu_pop_hl :: proc () { pop_16(&cpu_registers.hl) }
cpu_pop_af :: proc () {
    pop_16(&cpu_registers.af)
    cpu_registers.f &= 0xF0
}

cpu_call_nz :: proc () { call_cond(get_flag(.Z) == false) }
cpu_call_nc :: proc () { call_cond(get_flag(.C) == false) }
cpu_call_z  :: proc () { call_cond(get_flag(.Z) == true) }
cpu_call_c  :: proc () { call_cond(get_flag(.C) == true) }

cpu_call :: proc () {
    z := memory_bus_read(cpu_registers.pc); cpu_registers.pc += 1
    core_advance_cpu_clocks(4)
    w := memory_bus_read(cpu_registers.pc); cpu_registers.pc += 1
    core_advance_cpu_clocks(4)
    cpu_registers.sp -= 1
    core_advance_cpu_clocks(4)
    memory_bus_write(cpu_registers.sp, cast(u8)(cpu_registers.pc >> 8))
    cpu_registers.sp -= 1
    core_advance_cpu_clocks(4)
    memory_bus_write(cpu_registers.sp, cast(u8)(cpu_registers.pc & 0xFF))
    cpu_registers.pc = (cast(u16)w << 8) | cast(u16)z
    core_advance_cpu_clocks(4)
}

cpu_ret_nz :: proc () { ret_cond(get_flag(.Z) == false) }
cpu_ret_nc :: proc () { ret_cond(get_flag(.C) == false) }
cpu_ret_z  :: proc () { ret_cond(get_flag(.Z) == true) }
cpu_ret_c  :: proc () { ret_cond(get_flag(.C) == true) }

cpu_ret :: proc () {
    z := memory_bus_read(cpu_registers.sp); cpu_registers.sp += 1
    core_advance_cpu_clocks(4)

    w := memory_bus_read(cpu_registers.sp); cpu_registers.sp += 1
    core_advance_cpu_clocks(4)

    cpu_registers.pc = (cast(u16)w << 8) | cast(u16)z
    core_advance_cpu_clocks(4)
}

cpu_reti :: proc () {
    z := memory_bus_read(cpu_registers.sp); cpu_registers.sp += 1
    core_advance_cpu_clocks(4)
    w := memory_bus_read(cpu_registers.sp); cpu_registers.sp += 1
    core_advance_cpu_clocks(4)
    cpu_registers.pc = (cast(u16)w << 8) | cast(u16)z
    interrupt_master_enabled = true
    interrupt_enable_ime_delay = 0
    core_advance_cpu_clocks(4)
}

cpu_jp_nz :: proc () { jp_cond(get_flag(.Z) == false) }
cpu_jp_nc :: proc () { jp_cond(get_flag(.C) == false) }
cpu_jp_z  :: proc () { jp_cond(get_flag(.Z) == true) }
cpu_jp_c  :: proc () { jp_cond(get_flag(.C) == true) }

cpu_jr :: proc () {
    z := memory_bus_read(cpu_registers.pc); cpu_registers.pc += 1
    core_advance_cpu_clocks(4)

    w := cast(i32)cast(i8)z + cast(i32)cpu_registers.pc
    core_advance_cpu_clocks(4)

    cpu_registers.pc = cast(u16)(w & 0xFFFF)
}

cpu_jp_hl :: proc () {
    cpu_registers.pc = cpu_registers.hl
}

cpu_daa :: proc () {
    if !get_flag(.N) {
        if get_flag(.C) || cpu_registers.a > 0x99 {
            cpu_registers.a += 0x60
            set_flag(.C, true)
        }
        if get_flag(.H) || (cpu_registers.a & 0x0F) > 0x09 {
            cpu_registers.a += 0x6
        }
    } else {
        if get_flag(.C) {
            cpu_registers.a -= 0x60
        }
        if get_flag(.H) {
            cpu_registers.a -= 0x6
        }
    }
    set_flag(.Z, cpu_registers.a == 0)
    set_flag(.H, 0)
}

cpu_jr_nz :: proc () { jr_cond(get_flag(.Z) == false) }
cpu_jr_nc :: proc () { jr_cond(get_flag(.C) == false) }
cpu_jr_z  :: proc () { jr_cond(get_flag(.Z) == true) }
cpu_jr_c  :: proc () { jr_cond(get_flag(.C) == true) }

cpu_rlca  :: proc () {
    b7 := cpu_registers.a >> 7
    cpu_registers.a = cpu_registers.a << 1 | b7
    set_flag(.Z, 0)
    set_flag(.N, 0)
    set_flag(.H, 0)
    set_flag(.C, b7)
}

cpu_rla  :: proc () {
    b7 := cpu_registers.a >> 7
    cpu_registers.a = cpu_registers.a << 1 | (1 if get_flag(.C) else 0)
    set_flag(.Z, 0)
    set_flag(.N, 0)
    set_flag(.H, 0)
    set_flag(.C, b7)
}

cpu_rrca  :: proc () {
    b0 := cpu_registers.a & 0x1
    cpu_registers.a = b0 << 7 | cpu_registers.a >> 1
    set_flag(.Z, 0)
    set_flag(.N, 0)
    set_flag(.H, 0)
    set_flag(.C, b0)
}

cpu_rra  :: proc () {
    b0 := cpu_registers.a & 0x1
    cpu_registers.a = (0x80 if get_flag(.C) else 0) | cpu_registers.a >> 1
    set_flag(.Z, 0)
    set_flag(.N, 0)
    set_flag(.H, 0)
    set_flag(.C, b0)
}

cpu_cpl :: proc () {
    cpu_registers.a = ~cpu_registers.a
    set_flag(.N, 1)
    set_flag(.H, 1)
}

cpu_ld_16_sp :: proc () {
    z := memory_bus_read(cpu_registers.pc); cpu_registers.pc += 1
    core_advance_cpu_clocks(4)

    w := memory_bus_read(cpu_registers.pc); cpu_registers.pc += 1
    core_advance_cpu_clocks(4)

    wz := cast(u16)w << 8 | cast(u16)z
    memory_bus_write(wz, cast(u8)cpu_registers.sp); wz += 1
    core_advance_cpu_clocks(4)

    memory_bus_write(wz, cast(u8)(cpu_registers.sp >> 8))
    core_advance_cpu_clocks(4)
}

cpu_stop_wake_requested: bool

cpu_stop :: proc () {
    cpu_registers.pc += 1
    timer_on_div_write(0)

    cpu_stop_wake_requested = false
    cpu_run_state = .Stopped
}

cpu_stop_on_joypad_falling_edge :: proc () {
    if cpu_run_state == .Stopped {
        cpu_stop_wake_requested = true
    }
}

cpu_prefix_cb :: proc () {
    addr := cpu_registers.pc
    opcode := memory_bus_read(addr)
    cpu_registers.pc += 1
    core_advance_cpu_clocks(4)

    instruction := CPU_CB_INSTRUCTIONS[opcode]
    if instruction.procedure == nil {
        log.errorf("Unimplemented CB opcode: {:02X}, second byte at: {:04X}", opcode, addr)
    } else {
        instruction.procedure()
    }
}

cpu_rlc_b :: proc () { cpu_rlc_r8(&cpu_registers.b) }
cpu_rlc_c :: proc () { cpu_rlc_r8(&cpu_registers.c) }
cpu_rlc_d :: proc () { cpu_rlc_r8(&cpu_registers.d) }
cpu_rlc_e :: proc () { cpu_rlc_r8(&cpu_registers.e) }
cpu_rlc_h :: proc () { cpu_rlc_r8(&cpu_registers.h) }
cpu_rlc_l :: proc () { cpu_rlc_r8(&cpu_registers.l) }
cpu_rlc_a :: proc () { cpu_rlc_r8(&cpu_registers.a) }

cpu_rlc_ptr_hl :: proc () {
    z := memory_bus_read(cpu_registers.hl)
    core_advance_cpu_clocks(4)

    cpu_rlc_r8(&z)
    memory_bus_write(cpu_registers.hl, z)
    core_advance_cpu_clocks(4)
}

@(private="file")
cpu_rlc_r8 :: #force_inline proc (reg8: ^u8) {
    b7 := reg8^ >> 7
    reg8^ <<= 1
    reg8^ |= b7
    set_flag(.Z, reg8^ == 0)
    set_flag(.N, 0)
    set_flag(.H, 0)
    set_flag(.C, b7)
}

cpu_rrc_b :: proc () { cpu_rrc_r8(&cpu_registers.b) }
cpu_rrc_c :: proc () { cpu_rrc_r8(&cpu_registers.c) }
cpu_rrc_d :: proc () { cpu_rrc_r8(&cpu_registers.d) }
cpu_rrc_e :: proc () { cpu_rrc_r8(&cpu_registers.e) }
cpu_rrc_h :: proc () { cpu_rrc_r8(&cpu_registers.h) }
cpu_rrc_l :: proc () { cpu_rrc_r8(&cpu_registers.l) }
cpu_rrc_a :: proc () { cpu_rrc_r8(&cpu_registers.a) }

cpu_rrc_ptr_hl :: proc () {
    z := memory_bus_read(cpu_registers.hl)
    core_advance_cpu_clocks(4)

    cpu_rrc_r8(&z)
    memory_bus_write(cpu_registers.hl, z)
    core_advance_cpu_clocks(4)
}

@(private="file")
cpu_rrc_r8 :: #force_inline proc (reg8: ^u8) {
    b0 := reg8^ & 0x1
    reg8^ >>= 1
    reg8^ |= b0 << 7
    set_flag(.Z, reg8^ == 0)
    set_flag(.N, 0)
    set_flag(.H, 0)
    set_flag(.C, b0)
}

cpu_rl_b :: proc () { cpu_rl_r8(&cpu_registers.b) }
cpu_rl_c :: proc () { cpu_rl_r8(&cpu_registers.c) }
cpu_rl_d :: proc () { cpu_rl_r8(&cpu_registers.d) }
cpu_rl_e :: proc () { cpu_rl_r8(&cpu_registers.e) }
cpu_rl_h :: proc () { cpu_rl_r8(&cpu_registers.h) }
cpu_rl_l :: proc () { cpu_rl_r8(&cpu_registers.l) }
cpu_rl_a :: proc () { cpu_rl_r8(&cpu_registers.a) }

cpu_rl_ptr_hl :: proc () {
    z := memory_bus_read(cpu_registers.hl)
    core_advance_cpu_clocks(4)

    cpu_rl_r8(&z)
    memory_bus_write(cpu_registers.hl, z)
    core_advance_cpu_clocks(4)
}

@(private="file")
cpu_rl_r8 :: #force_inline proc (reg8: ^u8) {
    b7 := reg8^ >> 7
    reg8^ <<= 1
    reg8^ |= 1 if get_flag(.C) else 0
    set_flag(.Z, reg8^ == 0)
    set_flag(.N, 0)
    set_flag(.H, 0)
    set_flag(.C, b7)
}

cpu_rr_b :: proc () { cpu_rr_r8(&cpu_registers.b) }
cpu_rr_c :: proc () { cpu_rr_r8(&cpu_registers.c) }
cpu_rr_d :: proc () { cpu_rr_r8(&cpu_registers.d) }
cpu_rr_e :: proc () { cpu_rr_r8(&cpu_registers.e) }
cpu_rr_h :: proc () { cpu_rr_r8(&cpu_registers.h) }
cpu_rr_l :: proc () { cpu_rr_r8(&cpu_registers.l) }
cpu_rr_a :: proc () { cpu_rr_r8(&cpu_registers.a) }

cpu_rr_ptr_hl :: proc () {
    z := memory_bus_read(cpu_registers.hl)
    core_advance_cpu_clocks(4)

    cpu_rr_r8(&z)
    memory_bus_write(cpu_registers.hl, z)
    core_advance_cpu_clocks(4)
}

@(private="file")
cpu_rr_r8 :: #force_inline proc (reg8: ^u8) {
    b0 := reg8^ & 0x1
    reg8^ >>= 1
    reg8^ |= (1 << 7) if get_flag(.C) else 0
    set_flag(.Z, reg8^ == 0)
    set_flag(.N, 0)
    set_flag(.H, 0)
    set_flag(.C, b0)
}

cpu_sla_b :: proc () { cpu_sla_r8(&cpu_registers.b) }
cpu_sla_c :: proc () { cpu_sla_r8(&cpu_registers.c) }
cpu_sla_d :: proc () { cpu_sla_r8(&cpu_registers.d) }
cpu_sla_e :: proc () { cpu_sla_r8(&cpu_registers.e) }
cpu_sla_h :: proc () { cpu_sla_r8(&cpu_registers.h) }
cpu_sla_l :: proc () { cpu_sla_r8(&cpu_registers.l) }
cpu_sla_a :: proc () { cpu_sla_r8(&cpu_registers.a) }

cpu_sla_ptr_hl :: proc () {
    z := memory_bus_read(cpu_registers.hl)
    core_advance_cpu_clocks(4)

    cpu_sla_r8(&z)
    memory_bus_write(cpu_registers.hl, z)
    core_advance_cpu_clocks(4)
}

@(private="file")
cpu_sla_r8 :: #force_inline proc (reg8: ^u8) {
    b7 := reg8^ >> 7
    reg8^ <<= 1
    set_flag(.Z, reg8^ == 0)
    set_flag(.N, 0)
    set_flag(.H, 0)
    set_flag(.C, b7)
}

cpu_sra_b :: proc () { cpu_sra_r8(&cpu_registers.b) }
cpu_sra_c :: proc () { cpu_sra_r8(&cpu_registers.c) }
cpu_sra_d :: proc () { cpu_sra_r8(&cpu_registers.d) }
cpu_sra_e :: proc () { cpu_sra_r8(&cpu_registers.e) }
cpu_sra_h :: proc () { cpu_sra_r8(&cpu_registers.h) }
cpu_sra_l :: proc () { cpu_sra_r8(&cpu_registers.l) }
cpu_sra_a :: proc () { cpu_sra_r8(&cpu_registers.a) }

cpu_sra_ptr_hl :: proc () {
    z := memory_bus_read(cpu_registers.hl)
    core_advance_cpu_clocks(4)

    cpu_sra_r8(&z)
    memory_bus_write(cpu_registers.hl, z)
    core_advance_cpu_clocks(4)
}

@(private="file")
cpu_sra_r8 :: #force_inline proc (reg8: ^u8) {
    b0 := reg8^ & 0x1
    b7 := reg8^ & (1 << 7)
    reg8^ >>= 1
    reg8^ |= b7
    set_flag(.Z, reg8^ == 0)
    set_flag(.N, 0)
    set_flag(.H, 0)
    set_flag(.C, b0)
}

cpu_swap_b :: proc () { cpu_swap_r8(&cpu_registers.b) }
cpu_swap_c :: proc () { cpu_swap_r8(&cpu_registers.c) }
cpu_swap_d :: proc () { cpu_swap_r8(&cpu_registers.d) }
cpu_swap_e :: proc () { cpu_swap_r8(&cpu_registers.e) }
cpu_swap_h :: proc () { cpu_swap_r8(&cpu_registers.h) }
cpu_swap_l :: proc () { cpu_swap_r8(&cpu_registers.l) }
cpu_swap_a :: proc () { cpu_swap_r8(&cpu_registers.a) }

cpu_swap_ptr_hl :: proc () {
    z := memory_bus_read(cpu_registers.hl)
    core_advance_cpu_clocks(4)

    cpu_swap_r8(&z)
    memory_bus_write(cpu_registers.hl, z)
    core_advance_cpu_clocks(4)
}

@(private="file")
cpu_swap_r8 :: #force_inline proc (reg8: ^u8) {
    lo := reg8^ & 0x0F
    hi := reg8^ >> 4
    reg8^ = (lo << 4) | hi
    set_flag(.Z, reg8^ == 0)
    set_flag(.N, 0)
    set_flag(.H, 0)
    set_flag(.C, 0)
}

cpu_srl_b :: proc () { cpu_srl_r8(&cpu_registers.b) }
cpu_srl_c :: proc () { cpu_srl_r8(&cpu_registers.c) }
cpu_srl_d :: proc () { cpu_srl_r8(&cpu_registers.d) }
cpu_srl_e :: proc () { cpu_srl_r8(&cpu_registers.e) }
cpu_srl_h :: proc () { cpu_srl_r8(&cpu_registers.h) }
cpu_srl_l :: proc () { cpu_srl_r8(&cpu_registers.l) }
cpu_srl_a :: proc () { cpu_srl_r8(&cpu_registers.a) }

cpu_srl_ptr_hl :: proc () {
    z := memory_bus_read(cpu_registers.hl)
    core_advance_cpu_clocks(4)

    cpu_srl_r8(&z)
    memory_bus_write(cpu_registers.hl, z)
    core_advance_cpu_clocks(4)
}

@(private="file")
cpu_srl_r8 :: #force_inline proc (reg8: ^u8) {
    b0 := reg8^ & 0x1
    reg8^ >>= 1
    set_flag(.Z, reg8^ == 0)
    set_flag(.N, 0)
    set_flag(.H, 0)
    set_flag(.C, b0)
}

cpu_bit_0_b      :: proc () { cpu_bit_r8(cpu_registers.b, 0) }
cpu_bit_0_c      :: proc () { cpu_bit_r8(cpu_registers.c, 0) }
cpu_bit_0_d      :: proc () { cpu_bit_r8(cpu_registers.d, 0) }
cpu_bit_0_e      :: proc () { cpu_bit_r8(cpu_registers.e, 0) }
cpu_bit_0_h      :: proc () { cpu_bit_r8(cpu_registers.h, 0) }
cpu_bit_0_l      :: proc () { cpu_bit_r8(cpu_registers.l, 0) }
cpu_bit_0_ptr_hl :: proc () { cpu_bit_ptr_hl(0) }
cpu_bit_0_a      :: proc () { cpu_bit_r8(cpu_registers.a, 0) }

cpu_bit_1_b      :: proc () { cpu_bit_r8(cpu_registers.b, 1) }
cpu_bit_1_c      :: proc () { cpu_bit_r8(cpu_registers.c, 1) }
cpu_bit_1_d      :: proc () { cpu_bit_r8(cpu_registers.d, 1) }
cpu_bit_1_e      :: proc () { cpu_bit_r8(cpu_registers.e, 1) }
cpu_bit_1_h      :: proc () { cpu_bit_r8(cpu_registers.h, 1) }
cpu_bit_1_l      :: proc () { cpu_bit_r8(cpu_registers.l, 1) }
cpu_bit_1_ptr_hl :: proc () { cpu_bit_ptr_hl(1) }
cpu_bit_1_a      :: proc () { cpu_bit_r8(cpu_registers.a, 1) }

cpu_bit_2_b      :: proc () { cpu_bit_r8(cpu_registers.b, 2) }
cpu_bit_2_c      :: proc () { cpu_bit_r8(cpu_registers.c, 2) }
cpu_bit_2_d      :: proc () { cpu_bit_r8(cpu_registers.d, 2) }
cpu_bit_2_e      :: proc () { cpu_bit_r8(cpu_registers.e, 2) }
cpu_bit_2_h      :: proc () { cpu_bit_r8(cpu_registers.h, 2) }
cpu_bit_2_l      :: proc () { cpu_bit_r8(cpu_registers.l, 2) }
cpu_bit_2_ptr_hl :: proc () { cpu_bit_ptr_hl(2) }
cpu_bit_2_a      :: proc () { cpu_bit_r8(cpu_registers.a, 2) }

cpu_bit_3_b      :: proc () { cpu_bit_r8(cpu_registers.b, 3) }
cpu_bit_3_c      :: proc () { cpu_bit_r8(cpu_registers.c, 3) }
cpu_bit_3_d      :: proc () { cpu_bit_r8(cpu_registers.d, 3) }
cpu_bit_3_e      :: proc () { cpu_bit_r8(cpu_registers.e, 3) }
cpu_bit_3_h      :: proc () { cpu_bit_r8(cpu_registers.h, 3) }
cpu_bit_3_l      :: proc () { cpu_bit_r8(cpu_registers.l, 3) }
cpu_bit_3_ptr_hl :: proc () { cpu_bit_ptr_hl(3) }
cpu_bit_3_a      :: proc () { cpu_bit_r8(cpu_registers.a, 3) }

cpu_bit_4_b      :: proc () { cpu_bit_r8(cpu_registers.b, 4) }
cpu_bit_4_c      :: proc () { cpu_bit_r8(cpu_registers.c, 4) }
cpu_bit_4_d      :: proc () { cpu_bit_r8(cpu_registers.d, 4) }
cpu_bit_4_e      :: proc () { cpu_bit_r8(cpu_registers.e, 4) }
cpu_bit_4_h      :: proc () { cpu_bit_r8(cpu_registers.h, 4) }
cpu_bit_4_l      :: proc () { cpu_bit_r8(cpu_registers.l, 4) }
cpu_bit_4_ptr_hl :: proc () { cpu_bit_ptr_hl(4) }
cpu_bit_4_a      :: proc () { cpu_bit_r8(cpu_registers.a, 4) }

cpu_bit_5_b      :: proc () { cpu_bit_r8(cpu_registers.b, 5) }
cpu_bit_5_c      :: proc () { cpu_bit_r8(cpu_registers.c, 5) }
cpu_bit_5_d      :: proc () { cpu_bit_r8(cpu_registers.d, 5) }
cpu_bit_5_e      :: proc () { cpu_bit_r8(cpu_registers.e, 5) }
cpu_bit_5_h      :: proc () { cpu_bit_r8(cpu_registers.h, 5) }
cpu_bit_5_l      :: proc () { cpu_bit_r8(cpu_registers.l, 5) }
cpu_bit_5_ptr_hl :: proc () { cpu_bit_ptr_hl(5) }
cpu_bit_5_a      :: proc () { cpu_bit_r8(cpu_registers.a, 5) }

cpu_bit_6_b      :: proc () { cpu_bit_r8(cpu_registers.b, 6) }
cpu_bit_6_c      :: proc () { cpu_bit_r8(cpu_registers.c, 6) }
cpu_bit_6_d      :: proc () { cpu_bit_r8(cpu_registers.d, 6) }
cpu_bit_6_e      :: proc () { cpu_bit_r8(cpu_registers.e, 6) }
cpu_bit_6_h      :: proc () { cpu_bit_r8(cpu_registers.h, 6) }
cpu_bit_6_l      :: proc () { cpu_bit_r8(cpu_registers.l, 6) }
cpu_bit_6_ptr_hl :: proc () { cpu_bit_ptr_hl(6) }
cpu_bit_6_a      :: proc () { cpu_bit_r8(cpu_registers.a, 6) }

cpu_bit_7_b      :: proc () { cpu_bit_r8(cpu_registers.b, 7) }
cpu_bit_7_c      :: proc () { cpu_bit_r8(cpu_registers.c, 7) }
cpu_bit_7_d      :: proc () { cpu_bit_r8(cpu_registers.d, 7) }
cpu_bit_7_e      :: proc () { cpu_bit_r8(cpu_registers.e, 7) }
cpu_bit_7_h      :: proc () { cpu_bit_r8(cpu_registers.h, 7) }
cpu_bit_7_l      :: proc () { cpu_bit_r8(cpu_registers.l, 7) }
cpu_bit_7_ptr_hl :: proc () { cpu_bit_ptr_hl(7) }
cpu_bit_7_a      :: proc () { cpu_bit_r8(cpu_registers.a, 7) }

cpu_bit_ptr_hl :: proc (bit: u8) {
    z := memory_bus_read(cpu_registers.hl)
    core_advance_cpu_clocks(4)

    cpu_bit_r8(z, bit)
}

@(private="file")
cpu_bit_r8 :: #force_inline proc (reg8: u8, bit: u8) {
    set_flag(.Z, (reg8 & (1 << bit)) == 0)
    set_flag(.N, 0)
    set_flag(.H, 1)
}

cpu_res_0_b      :: proc () { cpu_res_r8(&cpu_registers.b, 0) }
cpu_res_0_c      :: proc () { cpu_res_r8(&cpu_registers.c, 0) }
cpu_res_0_d      :: proc () { cpu_res_r8(&cpu_registers.d, 0) }
cpu_res_0_e      :: proc () { cpu_res_r8(&cpu_registers.e, 0) }
cpu_res_0_h      :: proc () { cpu_res_r8(&cpu_registers.h, 0) }
cpu_res_0_l      :: proc () { cpu_res_r8(&cpu_registers.l, 0) }
cpu_res_0_ptr_hl :: proc () { cpu_res_ptr_hl(0) }
cpu_res_0_a      :: proc () { cpu_res_r8(&cpu_registers.a, 0) }

cpu_res_1_b      :: proc () { cpu_res_r8(&cpu_registers.b, 1) }
cpu_res_1_c      :: proc () { cpu_res_r8(&cpu_registers.c, 1) }
cpu_res_1_d      :: proc () { cpu_res_r8(&cpu_registers.d, 1) }
cpu_res_1_e      :: proc () { cpu_res_r8(&cpu_registers.e, 1) }
cpu_res_1_h      :: proc () { cpu_res_r8(&cpu_registers.h, 1) }
cpu_res_1_l      :: proc () { cpu_res_r8(&cpu_registers.l, 1) }
cpu_res_1_ptr_hl :: proc () { cpu_res_ptr_hl(1) }
cpu_res_1_a      :: proc () { cpu_res_r8(&cpu_registers.a, 1) }

cpu_res_2_b      :: proc () { cpu_res_r8(&cpu_registers.b, 2) }
cpu_res_2_c      :: proc () { cpu_res_r8(&cpu_registers.c, 2) }
cpu_res_2_d      :: proc () { cpu_res_r8(&cpu_registers.d, 2) }
cpu_res_2_e      :: proc () { cpu_res_r8(&cpu_registers.e, 2) }
cpu_res_2_h      :: proc () { cpu_res_r8(&cpu_registers.h, 2) }
cpu_res_2_l      :: proc () { cpu_res_r8(&cpu_registers.l, 2) }
cpu_res_2_ptr_hl :: proc () { cpu_res_ptr_hl(2) }
cpu_res_2_a      :: proc () { cpu_res_r8(&cpu_registers.a, 2) }

cpu_res_3_b      :: proc () { cpu_res_r8(&cpu_registers.b, 3) }
cpu_res_3_c      :: proc () { cpu_res_r8(&cpu_registers.c, 3) }
cpu_res_3_d      :: proc () { cpu_res_r8(&cpu_registers.d, 3) }
cpu_res_3_e      :: proc () { cpu_res_r8(&cpu_registers.e, 3) }
cpu_res_3_h      :: proc () { cpu_res_r8(&cpu_registers.h, 3) }
cpu_res_3_l      :: proc () { cpu_res_r8(&cpu_registers.l, 3) }
cpu_res_3_ptr_hl :: proc () { cpu_res_ptr_hl(3) }
cpu_res_3_a      :: proc () { cpu_res_r8(&cpu_registers.a, 3) }

cpu_res_4_b      :: proc () { cpu_res_r8(&cpu_registers.b, 4) }
cpu_res_4_c      :: proc () { cpu_res_r8(&cpu_registers.c, 4) }
cpu_res_4_d      :: proc () { cpu_res_r8(&cpu_registers.d, 4) }
cpu_res_4_e      :: proc () { cpu_res_r8(&cpu_registers.e, 4) }
cpu_res_4_h      :: proc () { cpu_res_r8(&cpu_registers.h, 4) }
cpu_res_4_l      :: proc () { cpu_res_r8(&cpu_registers.l, 4) }
cpu_res_4_ptr_hl :: proc () { cpu_res_ptr_hl(4) }
cpu_res_4_a      :: proc () { cpu_res_r8(&cpu_registers.a, 4) }

cpu_res_5_b      :: proc () { cpu_res_r8(&cpu_registers.b, 5) }
cpu_res_5_c      :: proc () { cpu_res_r8(&cpu_registers.c, 5) }
cpu_res_5_d      :: proc () { cpu_res_r8(&cpu_registers.d, 5) }
cpu_res_5_e      :: proc () { cpu_res_r8(&cpu_registers.e, 5) }
cpu_res_5_h      :: proc () { cpu_res_r8(&cpu_registers.h, 5) }
cpu_res_5_l      :: proc () { cpu_res_r8(&cpu_registers.l, 5) }
cpu_res_5_ptr_hl :: proc () { cpu_res_ptr_hl(5) }
cpu_res_5_a      :: proc () { cpu_res_r8(&cpu_registers.a, 5) }

cpu_res_6_b      :: proc () { cpu_res_r8(&cpu_registers.b, 6) }
cpu_res_6_c      :: proc () { cpu_res_r8(&cpu_registers.c, 6) }
cpu_res_6_d      :: proc () { cpu_res_r8(&cpu_registers.d, 6) }
cpu_res_6_e      :: proc () { cpu_res_r8(&cpu_registers.e, 6) }
cpu_res_6_h      :: proc () { cpu_res_r8(&cpu_registers.h, 6) }
cpu_res_6_l      :: proc () { cpu_res_r8(&cpu_registers.l, 6) }
cpu_res_6_ptr_hl :: proc () { cpu_res_ptr_hl(6) }
cpu_res_6_a      :: proc () { cpu_res_r8(&cpu_registers.a, 6) }

cpu_res_7_b      :: proc () { cpu_res_r8(&cpu_registers.b, 7) }
cpu_res_7_c      :: proc () { cpu_res_r8(&cpu_registers.c, 7) }
cpu_res_7_d      :: proc () { cpu_res_r8(&cpu_registers.d, 7) }
cpu_res_7_e      :: proc () { cpu_res_r8(&cpu_registers.e, 7) }
cpu_res_7_h      :: proc () { cpu_res_r8(&cpu_registers.h, 7) }
cpu_res_7_l      :: proc () { cpu_res_r8(&cpu_registers.l, 7) }
cpu_res_7_ptr_hl :: proc () { cpu_res_ptr_hl(7) }
cpu_res_7_a      :: proc () { cpu_res_r8(&cpu_registers.a, 7) }

cpu_res_ptr_hl :: proc (bit: u8) {
    z := memory_bus_read(cpu_registers.hl)
    core_advance_cpu_clocks(4)

    cpu_res_r8(&z, bit)
    memory_bus_write(cpu_registers.hl, z)
    core_advance_cpu_clocks(4)
}

@(private="file")
cpu_res_r8 :: #force_inline proc (reg8: ^u8, bit: u8) {
    mask := u8(1 << bit)
    reg8^ &= ~mask
}

cpu_set_0_b      :: proc () { cpu_set_r8(&cpu_registers.b, 0) }
cpu_set_0_c      :: proc () { cpu_set_r8(&cpu_registers.c, 0) }
cpu_set_0_d      :: proc () { cpu_set_r8(&cpu_registers.d, 0) }
cpu_set_0_e      :: proc () { cpu_set_r8(&cpu_registers.e, 0) }
cpu_set_0_h      :: proc () { cpu_set_r8(&cpu_registers.h, 0) }
cpu_set_0_l      :: proc () { cpu_set_r8(&cpu_registers.l, 0) }
cpu_set_0_ptr_hl :: proc () { cpu_set_ptr_hl(0) }
cpu_set_0_a      :: proc () { cpu_set_r8(&cpu_registers.a, 0) }

cpu_set_1_b      :: proc () { cpu_set_r8(&cpu_registers.b, 1) }
cpu_set_1_c      :: proc () { cpu_set_r8(&cpu_registers.c, 1) }
cpu_set_1_d      :: proc () { cpu_set_r8(&cpu_registers.d, 1) }
cpu_set_1_e      :: proc () { cpu_set_r8(&cpu_registers.e, 1) }
cpu_set_1_h      :: proc () { cpu_set_r8(&cpu_registers.h, 1) }
cpu_set_1_l      :: proc () { cpu_set_r8(&cpu_registers.l, 1) }
cpu_set_1_ptr_hl :: proc () { cpu_set_ptr_hl(1) }
cpu_set_1_a      :: proc () { cpu_set_r8(&cpu_registers.a, 1) }

cpu_set_2_b      :: proc () { cpu_set_r8(&cpu_registers.b, 2) }
cpu_set_2_c      :: proc () { cpu_set_r8(&cpu_registers.c, 2) }
cpu_set_2_d      :: proc () { cpu_set_r8(&cpu_registers.d, 2) }
cpu_set_2_e      :: proc () { cpu_set_r8(&cpu_registers.e, 2) }
cpu_set_2_h      :: proc () { cpu_set_r8(&cpu_registers.h, 2) }
cpu_set_2_l      :: proc () { cpu_set_r8(&cpu_registers.l, 2) }
cpu_set_2_ptr_hl :: proc () { cpu_set_ptr_hl(2) }
cpu_set_2_a      :: proc () { cpu_set_r8(&cpu_registers.a, 2) }

cpu_set_3_b      :: proc () { cpu_set_r8(&cpu_registers.b, 3) }
cpu_set_3_c      :: proc () { cpu_set_r8(&cpu_registers.c, 3) }
cpu_set_3_d      :: proc () { cpu_set_r8(&cpu_registers.d, 3) }
cpu_set_3_e      :: proc () { cpu_set_r8(&cpu_registers.e, 3) }
cpu_set_3_h      :: proc () { cpu_set_r8(&cpu_registers.h, 3) }
cpu_set_3_l      :: proc () { cpu_set_r8(&cpu_registers.l, 3) }
cpu_set_3_ptr_hl :: proc () { cpu_set_ptr_hl(3) }
cpu_set_3_a      :: proc () { cpu_set_r8(&cpu_registers.a, 3) }

cpu_set_4_b      :: proc () { cpu_set_r8(&cpu_registers.b, 4) }
cpu_set_4_c      :: proc () { cpu_set_r8(&cpu_registers.c, 4) }
cpu_set_4_d      :: proc () { cpu_set_r8(&cpu_registers.d, 4) }
cpu_set_4_e      :: proc () { cpu_set_r8(&cpu_registers.e, 4) }
cpu_set_4_h      :: proc () { cpu_set_r8(&cpu_registers.h, 4) }
cpu_set_4_l      :: proc () { cpu_set_r8(&cpu_registers.l, 4) }
cpu_set_4_ptr_hl :: proc () { cpu_set_ptr_hl(4) }
cpu_set_4_a      :: proc () { cpu_set_r8(&cpu_registers.a, 4) }

cpu_set_5_b      :: proc () { cpu_set_r8(&cpu_registers.b, 5) }
cpu_set_5_c      :: proc () { cpu_set_r8(&cpu_registers.c, 5) }
cpu_set_5_d      :: proc () { cpu_set_r8(&cpu_registers.d, 5) }
cpu_set_5_e      :: proc () { cpu_set_r8(&cpu_registers.e, 5) }
cpu_set_5_h      :: proc () { cpu_set_r8(&cpu_registers.h, 5) }
cpu_set_5_l      :: proc () { cpu_set_r8(&cpu_registers.l, 5) }
cpu_set_5_ptr_hl :: proc () { cpu_set_ptr_hl(5) }
cpu_set_5_a      :: proc () { cpu_set_r8(&cpu_registers.a, 5) }

cpu_set_6_b      :: proc () { cpu_set_r8(&cpu_registers.b, 6) }
cpu_set_6_c      :: proc () { cpu_set_r8(&cpu_registers.c, 6) }
cpu_set_6_d      :: proc () { cpu_set_r8(&cpu_registers.d, 6) }
cpu_set_6_e      :: proc () { cpu_set_r8(&cpu_registers.e, 6) }
cpu_set_6_h      :: proc () { cpu_set_r8(&cpu_registers.h, 6) }
cpu_set_6_l      :: proc () { cpu_set_r8(&cpu_registers.l, 6) }
cpu_set_6_ptr_hl :: proc () { cpu_set_ptr_hl(6) }
cpu_set_6_a      :: proc () { cpu_set_r8(&cpu_registers.a, 6) }

cpu_set_7_b      :: proc () { cpu_set_r8(&cpu_registers.b, 7) }
cpu_set_7_c      :: proc () { cpu_set_r8(&cpu_registers.c, 7) }
cpu_set_7_d      :: proc () { cpu_set_r8(&cpu_registers.d, 7) }
cpu_set_7_e      :: proc () { cpu_set_r8(&cpu_registers.e, 7) }
cpu_set_7_h      :: proc () { cpu_set_r8(&cpu_registers.h, 7) }
cpu_set_7_l      :: proc () { cpu_set_r8(&cpu_registers.l, 7) }
cpu_set_7_ptr_hl :: proc () { cpu_set_ptr_hl(7) }
cpu_set_7_a      :: proc () { cpu_set_r8(&cpu_registers.a, 7) }

cpu_set_ptr_hl :: proc (bit: u8) {
    z := memory_bus_read(cpu_registers.hl)
    core_advance_cpu_clocks(4)

    cpu_set_r8(&z, bit)
    memory_bus_write(cpu_registers.hl, z)
    core_advance_cpu_clocks(4)
}

@(private="file")
cpu_set_r8 :: #force_inline proc (reg8: ^u8, bit: u8) {
    mask := u8(1 << bit)
    reg8^ |= mask
}

@(private="file")
inc_r8 :: #force_inline proc (reg: ^u8) {
    hc := (reg^ & 0xF) == 0xF
    reg^ += 1
    set_flag(.N, 0)
    set_flag(.H, hc)
    set_flag(.Z, reg^ == 0)
}

@(private="file")
dec_r8 :: #force_inline proc (reg: ^u8) {
    hc := (reg^ & 0xF) == 0
    reg^ -= 1
    set_flag(.N, 1)
    set_flag(.H, hc)
    set_flag(.Z, reg^ == 0)
}

@(private="file")
inc_r16 :: #force_inline proc (reg: ^u16) {
    reg^ += 1
    core_advance_cpu_clocks(4)
}

@(private="file")
dec_r16 :: #force_inline proc (reg: ^u16) {
    reg^ -= 1
    core_advance_cpu_clocks(4)
}

@(private="file")
add_hl_16 :: #force_inline proc (reg16: u16) {
    hl := cpu_registers.hl
    sum := cast(u32)hl + cast(u32)reg16
    core_advance_cpu_clocks(4)

    cpu_registers.hl = cast(u16)sum
    set_flag(.N, 0)
    set_flag(.H, (hl & 0x0FFF) + (reg16 & 0x0FFF) > 0x0FFF)
    set_flag(.C, sum > 0xFFFF)
}

@(private="file")
add_to_a :: #force_inline proc (operand: u8) {
    sum := cast(u16)cpu_registers.a + cast(u16)operand
    set_flag(.Z, cast(u8)sum == 0)
    set_flag(.N, 0)
    set_flag(.H, (operand & 0xF) + (cpu_registers.a & 0xF) > 0xF)
    set_flag(.C, sum > 0xFF)
    cpu_registers.a = cast(u8)sum
}

@(private="file")
adc_to_a :: #force_inline proc (operand: u8) {
    c := u16(1) if get_flag(.C) else u16(0)
    sum := cast(u16)cpu_registers.a + cast(u16)operand + c
    set_flag(.Z, cast(u8)sum == 0)
    set_flag(.N, 0)
    set_flag(.H, (operand & 0xF) + (cpu_registers.a & 0xF) + cast(u8)c > 0xF)
    set_flag(.C, sum > 0xFF)
    cpu_registers.a = cast(u8)sum
}

@(private="file")
sub_to_a :: #force_inline proc (operand: u8) {
    sub := cast(u16)cpu_registers.a - cast(u16)operand
    set_flag(.Z, sub == 0)
    set_flag(.N, 1)
    set_flag(.H, (cpu_registers.a & 0xF) < (operand & 0xF))
    set_flag(.C, cpu_registers.a < operand)
    cpu_registers.a = cast(u8)sub
}

@(private="file")
sbc_to_a :: #force_inline proc (operand: u8) {
    c := u16(1) if get_flag(.C) else u16(0)
    sub := cast(u16)cpu_registers.a - cast(u16)operand - c
    set_flag(.Z, cast(u8)sub == 0)
    set_flag(.N, 1)
    set_flag(.H, (cpu_registers.a & 0xF) < (operand & 0xF) + cast(u8)c)
    set_flag(.C, cast(u16)cpu_registers.a < cast(u16)operand + c)
    cpu_registers.a = cast(u8)sub
}

@(private="file")
and_with_a :: #force_inline proc (operand: u8) {
    cpu_registers.a &= operand
    set_flag(.Z, 1 if cpu_registers.a == 0 else 0)
    set_flag(.N, 0)
    set_flag(.H, 1)
    set_flag(.C, 0)
}

@(private="file")
xor_with_a :: #force_inline proc (operand: u8) {
    cpu_registers.a ~= operand
    set_flag(.Z, 1 if cpu_registers.a == 0 else 0)
    set_flag(.N, 0)
    set_flag(.H, 0)
    set_flag(.C, 0)
}

@(private="file")
or_with_a :: #force_inline proc (operand: u8) {
    cpu_registers.a |= operand
    set_flag(.Z, 1 if cpu_registers.a == 0 else 0)
    set_flag(.N, 0)
    set_flag(.H, 0)
    set_flag(.C, 0)
}

@(private="file")
cp_with_a :: #force_inline proc (operand: u8) {
    // same as sub, but doens't update the A register
    sub := cast(u16)cpu_registers.a - cast(u16)operand
    set_flag(.Z, sub == 0)
    set_flag(.N, 1)
    set_flag(.H, (cpu_registers.a & 0xF) < (operand & 0xF))
    set_flag(.C, cpu_registers.a < operand)
}

@(private="file")
ld_8 :: #force_inline proc (reg: ^u8) {
    value := memory_bus_read(cpu_registers.pc)
    cpu_registers.pc += 1
    core_advance_cpu_clocks(4)

    reg^ = value
}

@(private="file")
ld_16 :: #force_inline proc (reg16: ^u16) {
    z := memory_bus_read(cpu_registers.pc)
    cpu_registers.pc += 1
    core_advance_cpu_clocks(4)

    w := memory_bus_read(cpu_registers.pc)
    cpu_registers.pc += 1
    core_advance_cpu_clocks(4)

    reg16^ = cast(u16)z | (cast(u16)w << 8)
}

@(private="file")
ld_8_ptr :: #force_inline proc (dst_reg16: u16, src_reg8: u8) {
    memory_bus_write(dst_reg16, src_reg8)
    core_advance_cpu_clocks(4)
}

@(private="file")
ld_r8_from_ptr :: #force_inline proc (dst_reg8: ^u8, src_reg16: u16) {
    z := memory_bus_read(src_reg16)
    core_advance_cpu_clocks(4)

    dst_reg8^ = z
}

@(private="file")
rst_nn :: #force_inline proc (addr: u16) {
    cpu_registers.sp -= 1
    core_advance_cpu_clocks(4)

    memory_bus_write(cpu_registers.sp, cast(u8)(cpu_registers.pc >> 8))
    cpu_registers.sp -= 1
    core_advance_cpu_clocks(4)

    memory_bus_write(cpu_registers.sp, cast(u8)cpu_registers.pc)
    cpu_registers.pc = addr
    core_advance_cpu_clocks(4)

}

@(private="file")
push_16 :: #force_inline proc (reg16: u16) {
    cpu_registers.sp -= 1
    core_advance_cpu_clocks(4)

    memory_bus_write(cpu_registers.sp, cast(u8)(reg16 >> 8))
    cpu_registers.sp -= 1
    core_advance_cpu_clocks(4)

    memory_bus_write(cpu_registers.sp, cast(u8)reg16)
    core_advance_cpu_clocks(4)
}

@(private="file")
pop_16 :: #force_inline proc (reg16: ^u16) {
    z := memory_bus_read(cpu_registers.sp); cpu_registers.sp += 1
    core_advance_cpu_clocks(4)

    w := memory_bus_read(cpu_registers.sp); cpu_registers.sp += 1
    core_advance_cpu_clocks(4)

    reg16^ = cast(u16)w << 8 | cast(u16)z
}

@(private="file")
call_cond :: #force_inline proc (cond: bool) {
    z := memory_bus_read(cpu_registers.pc); cpu_registers.pc += 1
    core_advance_cpu_clocks(4)

    w := memory_bus_read(cpu_registers.pc); cpu_registers.pc += 1
    core_advance_cpu_clocks(4)

    if cond {
        cpu_registers.sp -= 1
        core_advance_cpu_clocks(4)

        memory_bus_write(cpu_registers.sp, cast(u8)(cpu_registers.pc >> 8)); cpu_registers.sp -= 1
        core_advance_cpu_clocks(4)

        memory_bus_write(cpu_registers.sp, cast(u8)cpu_registers.pc)
        cpu_registers.pc = cast(u16)w << 8 | cast(u16)z
        core_advance_cpu_clocks(4)
    }
}

@(private="file")
ret_cond :: #force_inline proc (cond: bool) {
    core_advance_cpu_clocks(4)
    if cond {
        z := memory_bus_read(cpu_registers.sp); cpu_registers.sp += 1
        core_advance_cpu_clocks(4)

        w := memory_bus_read(cpu_registers.sp); cpu_registers.sp += 1
        core_advance_cpu_clocks(4)

        cpu_registers.pc = cast(u16)w << 8 | cast(u16)z
        core_advance_cpu_clocks(4)
    }
}

@(private="file")
jp_cond :: #force_inline proc (cond: bool) {
    z := memory_bus_read(cpu_registers.pc); cpu_registers.pc += 1
    core_advance_cpu_clocks(4)

    w := memory_bus_read(cpu_registers.pc); cpu_registers.pc += 1
    core_advance_cpu_clocks(4)

    if cond {
        cpu_registers.pc = cast(u16)w << 8 | cast(u16)z
        core_advance_cpu_clocks(4)
    }
}

@(private="file")
jr_cond :: #force_inline proc (cond: bool) {
    z := memory_bus_read(cpu_registers.pc); cpu_registers.pc += 1
    core_advance_cpu_clocks(4)

    if cond {
        // computation for address performed here
        wz := cast(u16)((cast(i32)cpu_registers.pc + cast(i32)(cast(i8)z)) & 0xFFFF)
        core_advance_cpu_clocks(4)

        cpu_registers.pc = wz
    }
}

@(private="file")
get_flag :: #force_inline proc ($flag: CpuFlag) -> bool {
    return (cast(u8)flag & cpu_registers.f) != 0
}

@(private="file")
set_flag_value :: #force_inline proc ($flag: CpuFlag, value: u8) {
    if value > 0 {
        cpu_registers.f |= cast(u8)flag
    } else {
        cpu_registers.f &= ~cast(u8)flag
    }
}

@(private="file")
set_flag_bool :: #force_inline proc ($flag: CpuFlag, on: bool) {
    if on {
        cpu_registers.f |= cast(u8)flag
    } else {
        cpu_registers.f &= ~cast(u8)flag
    }
}

set_flag :: proc {
    set_flag_value,
    set_flag_bool,
}
