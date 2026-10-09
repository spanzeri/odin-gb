package odin_gb

JOYPAD_REGISTER_ADDRESS :: 0xFF00

joypad_read_input :: proc () -> u8 {
    register := system_memory[JOYPAD_REGISTER_ADDRESS]
    register |= 0b1100_0000
    register &= 0xF0
    action_buttons := check_bit(register, 5)
    direction_buttons := check_bit(register, 4)
    if action_buttons && direction_buttons {
        register |= 0x0F
    } else {
        if !action_buttons {
            change_bit(&register, 1 if !joypad.start else 0, 3)
            change_bit(&register, 1 if !joypad.select else 0, 2)
            change_bit(&register, 1 if !joypad.b else 0, 1)
            change_bit(&register, 1 if !joypad.a else 0, 0)
        } else if !direction_buttons {
            change_bit(&register, 1 if !joypad.down else 0, 3)
            change_bit(&register, 1 if !joypad.up else 0, 2)
            change_bit(&register, 1 if !joypad.left else 0, 1)
            change_bit(&register, 1 if !joypad.right else 0, 0)
        }
    }

    system_memory[JOYPAD_REGISTER_ADDRESS] = register
    return register
}

joypad_write_input :: proc (flags: u8) {
    action_buttons := check_bit(flags, 5)
    direction_buttons := check_bit(flags, 4)
    register := system_memory[JOYPAD_REGISTER_ADDRESS]
    change_bit(&register, 1 if action_buttons else 0, 5)
    change_bit(&register, 1 if direction_buttons else 0, 4)
    system_memory[JOYPAD_REGISTER_ADDRESS] = register
}

joypad_on_button_a      :: proc(pressed: bool) { on_action_button(&joypad.a, pressed) }
joypad_on_button_b      :: proc(pressed: bool) { on_action_button(&joypad.b, pressed) }
joypad_on_button_select :: proc(pressed: bool) { on_action_button(&joypad.select, pressed) }
joypad_on_button_start  :: proc(pressed: bool) { on_action_button(&joypad.start, pressed) }
joypad_on_dpad_right    :: proc(pressed: bool) { on_direction_button(&joypad.right, pressed) }
joypad_on_dpad_left     :: proc(pressed: bool) { on_direction_button(&joypad.left, pressed) }
joypad_on_dpad_up       :: proc(pressed: bool) { on_direction_button(&joypad.up, pressed) }
joypad_on_dpad_down     :: proc(pressed: bool) { on_direction_button(&joypad.down, pressed) }

@(private="file")
on_action_button :: #force_inline proc(button: ^bool, pressed: bool) {
    action_flags := check_bit(system_memory[JOYPAD_REGISTER_ADDRESS], 5)
    check_button(button, pressed, action_flags)
}

@(private="file")
on_direction_button :: #force_inline proc(button: ^bool, pressed: bool) {
    direction_flag := check_bit(system_memory[JOYPAD_REGISTER_ADDRESS], 4)
    check_button(button, pressed, direction_flag)
}

@(private="file")
check_button :: #force_inline proc(button: ^bool, pressed: bool, flag: bool) {
    if button^ != pressed {
        if !flag && button^ && !pressed {
            interrupt_raise_flag(.Joypad)
        }
        button^ = pressed
    }
}

@(private="file")
JoypadState :: struct {
    a: bool,
    b: bool,
    select: bool,
    start: bool,
    right: bool,
    left: bool,
    up: bool,
    down: bool,
}

@(private="file")
joypad: JoypadState

