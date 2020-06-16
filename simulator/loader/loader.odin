package main

import "core:fmt"
import "core:os"
import "core:mem"
import "core:strings"
import "elf"



RAM_SIZE :: 1024 * 1024;
ram : []byte;





Reg :: enum {
	X0, X1,  X2,  X3,  X4,  X5,  X6,  X7,  X8,
	X9,  X10, X11, X12, X13, X14, X15, X16,
	X17, X18, X19, X20, X21, X22, X23, X24,
	X25, X26, X27, X28, X29, X30, X31, 

}


/*
	standard calling convention calls for register x1 to be return address,
	x5 to be a link register, and x2 to be the stack pointer
*/
CPU :: struct {
	registers: [32]Reg,
	pc: Reg
}



Opcode :: enum {
	//RV32I opcodes
	LUI,
	AUIPC,
	JAL,
	JALR,
	BEQ,
	BNE,
	BLT,
	BGE,
	BLTU,
	BGEU,
	LB,
	LH,
	LW,
	LBU,
	LHU,
	SB,
	SH,
	SW,
	ADDI,
	SLTI,
	SLTIU,
	XORI,
	ORI,
	ANDI,
	SLLI,
	SRLI,
	SRAI,
	ADD,
	SUB,
	SLL,
	SLT,
	SLTU,
	XOR,
	SRL,
	SRA,
	OR,
	AND,
	FENCE,
	ECALL,
	EBREAK,


	//RV64I opcodes
}

Instruction :: struct {
	op: Opcode
	
	rd: Reg,
	rs1: Reg,
	rs2: Reg,

	imm: i32
}




decode :: proc(ibits: u32) -> (Instruction, bool) {

	rd :: proc(ibits: u32) -> Reg {
		return Reg((ibits >> 7) & 0x1f);
	}

	rs1 :: proc(ibits: u32) -> Reg {
		return Reg((ibits >> 15) & 0x1f);
	}

	rs2 :: proc(ibits: u32) -> Reg {
		return Reg((ibits >> 20) & 0x1f);
	}

	func3 :: proc(ibits: u32) -> byte {
		return byte((ibits >> 12) & 0x3);
	}

	func7 :: proc(ibits: u32) -> byte {
		return byte((ibits >> 25) & 0x7f);
	}

	unsigned_bits :: proc(bits: u32, start: u32, length: u32) -> u32 {
		assert(length > 0);
		mask : u32 = 0xffffffff >> (32 - length);
		return (bits >> start) & mask;
	};

	i_immediate :: proc(bits: u32) -> i32 {
		return i32(bits) >> 20; //sign extend
	}

	s_immediate :: proc(bits: u32) -> i32 {
		return i32((unsigned_bits(bits, 7, 5)) |
					(u32(i32(bits) >> 20) & 0xffff_ffe0)); // sign extend
	}

	b_immediate :: proc(bits: u32) -> i32 {
		return i32((unsigned_bits(bits, 8, 4) << 1) |
					(unsigned_bits(bits, 25, 6) << 5) |
					(unsigned_bits(bits, 7, 1) << 11) |
					(u32(i32(bits) >> 19) & 0xffff_f000));
	}

	u_immediate :: proc(bits: u32) -> i32 {
		return i32(bits & 0xffff_f000);
	}


	j_immediate :: proc(bits: u32) -> i32 {
		return i32((unsigned_bits(bits, 21, 10) << 1) |
					(unsigned_bits(bits, 20, 1) << 11) |
					(unsigned_bits(bits, 12, 8) << 12) |
					(u32((i32(bits) >> 11) & 0xffe)));
	}




	instr: Instruction;
	opcode := byte(ibits & 0x7f);
	
	switch(opcode) {
		case 0x37:
			instr.op = .LUI;
			instr.rd = rd(ibits);
		case 0x17:
			instr.op = .AUIPC;
			instr.rd = rd(ibits);
		case 0x6f: 
			instr.op = .JAL;
			instr.rd = rd(ibits);
			instr.imm = j_immediate(ibits);
		case 0x67: 
			if func3(ibits) == 0 {	
				instr.op = .JALR;
				instr.rd = rd(ibits);
				instr.rs1 = rs1(ibits);
				instr.imm = i_immediate(ibits);
			} else {
				fmt.eprintln("invalid func3 for JALR instruction");
				return instr, false;
			}
			
		case 0x63: 
			//B-type instructions
			instr.rd  = rd(ibits);
			instr.rs1 = rs1(ibits);
			instr.rs2 = rs2(ibits);
			instr.imm = b_immediate(ibits);
			switch func3(ibits) {
				case 0x0: instr.op = .BEQ;
				case 0x1: instr.op = .BNE;
				case 0x4: instr.op = .BLT;
				case 0x5: instr.op = .BGE;
				case 0x6: instr.op = .BLTU;
				case 0x7: instr.op = .BGEU;
				case:
					fmt.eprintln("invalid instruction!");
					return instr, false;
			}

		case 0x03: 
			//load instructoins				
			instr.rd = rd(ibits);
			instr.rs1 = rs1(ibits);
			instr.imm = i_immediate(ibits);
			switch func3(ibits) {

				case 0x0: instr.op = .LB;
				case 0x1: instr.op = .LH;
				case 0x2: instr.op = .LW;
				case 0x4: instr.op = .LBU;
				case 0x5: instr.op = .LHU;
				case:
					fmt.eprintln("invalid instruction!");
					return instr, false;
			}

		case 0x23:
			//store instructions
			instr.rs1 = rs1(ibits);
			instr.rs2 = rs2(ibits);
			instr.imm = s_immediate(ibits);

			switch func3(ibits) {
				case 0x0: instr.op = .SW;
				case 0x1: instr.op = .SH;
				case 0x2: instr.op = .SW;
				case: 
					fmt.eprintln("invalid instruction!");
					return instr, false;
			}

		case 0x13:
			//immediate instructions
			instr.rd = rd(ibits);
			instr.rs1 = rs1(ibits);
			instr.imm = i_immediate(ibits);

			switch f3 := func3(ibits); f3 {
				case 0x0: instr.op = .ADDI;
				case 0x2: instr.op = .SLTI;
				case 0x3: instr.op = .SLTIU;
				case 0x4: instr.op = .XORI;
				case 0x6: instr.op = .ORI;
				case 0x7: instr.op = .ANDI;
				case 0x1, 0x5:	//shift by constant
				  f7 := func7(ibits);
					instr.imm &= 0x1f; //erase the top bits of the immediate to prepare for shifting
					if(f3 == 0x1) {
						if(f7 != 0) {
							fmt.eprintln("shift instruction not properly formatted: func7 must be 0x0 or 0x20");
							return instr, false;
						} else {
							instr.op = .SLLI;
						}						
					} else {
						//f3 == 0x5;
						if f7 == 0 {
							instr.op = .SRLI;
						} else if f7 == 0x20 {
							instr.op = .SRAI;
						} else {
							fmt.eprintln("shift instruction not properly formatted");
							return instr, false;
						}
					}
			}

		case 0x33:
			//normal register instructions 
			instr.rd = rd(ibits);
			instr.rs1 = rs1(ibits);
			instr.rs2 = rs2(ibits);

			f7 := func7(ibits);
			f3 := func3(ibits);

			if(f7 == 0) {
				switch f3 {
					case 0x0: instr.op = .ADD;
					case 0x1: instr.op = .SUB;
					case 0x2: instr.op = .SLT;
					case 0x3: instr.op = .SLTU;
					case 0x4: instr.op = .XOR;
					case 0x5: instr.op = .SRL;
					case 0x6: instr.op = .OR;
					case 0x7: instr.op = .AND;
				}
			} else if f7 == 0x20 {
				switch f3 {
					case 0x0: instr.op = .SUB;
					case 0x5: instr.op = .SRA;
					case: 
						fmt.eprint("improper func7/func3 combination for register instruction");
						return instr, false;
				}
			} else {
				fmt.eprint("improper func7 for this opcode");
				return instr, false;
			}

			switch func3(ibits) {
				case 0:
					if func7(ibits) == 0 {
						instr.op = .ADD;
					} else if func7(ibits) == 0x20 {
						instr.op = .SUB;
					} else {
						fmt.eprint("disallowed func7 for ADD/SUB instruction");
						return instr, false;
					}
				case 0x1:
					if func7(ibits) == 0 {
						fmt.eprint("disallowed func7 for SLL instruction");
						return instr, false;
					} else {
						instr.op = .SLL;
					}
			}

		case:
		fmt.eprintf("invalid instruction: unrecognized opcode: 0x%x\n", opcode);
		return instr, false;
	}

	return instr, true;
}




load :: proc(buffer: []byte, elf_file: ^elf.Elf32_File) -> bool {
	
	for _, i in elf_file.section_headers {
		sh := &elf_file.section_headers[i];
		name: string = elf.lookup_section_name(elf_file, sh);
		switch name {
			case ".rodata", ".text":
				if(sh.addr + sh.size > RAM_SIZE) {
					fmt.eprint("RAM_SIZE too small to load this section\n");
					return false;
				} else {
					mem.copy(&buffer[sh.addr], &elf_file.data[sh.offset], int(sh.size));
				}
			case ".bss":
				if(sh.addr + sh.size > RAM_SIZE) {
					fmt.eprint("RAM_SIZE too small to load this section\n");
					return false;
				} else {
					//TODO this probably isn't even necessary in our current setup, but whatever
					mem.set(&buffer[sh.addr], 0, int(sh.size));
				}
		}
	}

	return true;
}





disassemble :: proc(elf_file: ^elf.Elf32_File) {
	for _, sh_index in elf_file.section_headers {
		sh := &elf_file.section_headers[sh_index];
		if elf.lookup_section_name(elf_file, sh) == ".text" {
			fmt.println("Disassembly of section .text:\n");

			slice := elf_file.data[sh.offset : sh.size + sh.offset];
			words := mem.slice_data_cast([]u32, slice);
			for word, j in words {
				instr, ok := decode(word);
				if (ok) {
					address := u32(j * 4) + sh.addr;

					sym := elf.global_sym_by_address(elf_file, address, u16(sh_index));
					if(sym != nil) {
						fmt.printf("\n%x <%s>\n", address, elf.sym_name(elf_file, sym));
					}
					fmt.printf("%x: ", address); 
					fmt.print(instr);
					fmt.println();
				}
			}
			break;
		}
	}
}





scratch :: proc() {
	fmt.printf("%10s %-10s asdf\n", "adf", "asdfasdf");
	fmt.printf("%10s %-10s asdf\n", "af", "asdff");
	fmt.printf("%10s %-10s asdf\n", "asdfdd", "asdfasdfsdf");
	fmt.printf("%10s %-10s asdf\n", "asdfssdf", "asdfasdf");



	// fmt.println(-13);
	// fmt.println(abs(-13));
}



main :: proc() {


	// scratch();
	// os.exit(0);
	

	ram = make([]byte, RAM_SIZE);
	//fmt.printf("RAM: 0x%x\n", &ram[0]);

	if(len(os.args) < 2) {
		fmt.eprint("Usage: loader [PATH_TO_ELF_FILE].elf");
		os.exit(1);
	}

	file_bytes, success := os.read_entire_file(os.args[1]);
	if(success) {
		elf_file: elf.Elf32_File = elf.parse(file_bytes);
		elf.print_report(&elf_file);
		ok := load(ram, &elf_file);
		if(!ok) {
			fmt.eprint("Error loading program");
			os.exit(1);
		}

		disassemble(&elf_file);
	} else {
		fmt.eprint("Error opening ELF file");
		os.exit(1);
	}
}