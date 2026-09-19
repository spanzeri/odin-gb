package odin_gb

import "core:log"
import "core:fmt"
import "core:os"

@(private="file")
log_to_console := false

@(private="file")
log_to_file := true

@(private="file")
output_file: ^os.File

debug_log :: proc (format: string, args: ..any) {
    if log_to_console {
        fmt.eprintfln(format, ..args)
    }
    if log_to_file {
        if output_file == nil {
            if file, err := os.create("logfile.txt"); err != nil {
                log.error("Failed to open log file")
                return
            } else {
                output_file = file
            }
        }

        if output_file != nil {
            fmt.wprintfln(os.to_writer(output_file), format, ..args)
        }
    }
}

debug_log_close :: proc () {
    if output_file != nil {
        os.close(output_file)
        log_to_file = false
        output_file = nil
    }
}
