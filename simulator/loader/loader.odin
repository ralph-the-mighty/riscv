package main

import "core:fmt"
import "core:os"
import "core:mem"
import "core:strings"
import "elf"




main :: proc() {

	if(len(os.args) < 2) {
		fmt.eprint("Usage: loader [PATH_TO_ELF_FILE].elf");
		os.exit(1);
	}

	file_bytes, success := os.read_entire_file(os.args[1]);
	if(success) {
		elf_file: elf.Elf32_File = elf.parse(file_bytes);
		elf.print_report(elf_file);
	} else {
		fmt.eprint("Error loading file");
		os.exit(1);
	}
}