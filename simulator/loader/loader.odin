package main

import "core:fmt"
import "core:os"
import "core:mem"
import "core:strings"
import "elf"




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
	registers: [32]i32,
	pc: u32,
	ram: []byte
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
}

@static
opcode_names := map[Opcode]string{
	.LUI = "lui",
	.AUIPC = "auipc",
	.JAL = "jal",
	.JALR = "jalr",
	.BEQ = "beq",
	.BNE = "bne",
	.BLT = "blt",
	.BGE = "bge",
	.BLTU = "bltu",
	.BGEU = "bgeu",
	.LB = "lb",
	.LH = "lh",
	.LW = "lw",
	.LBU = "lbu",
	.LHU = "lhu",
	.SB = "sb",
	.SH = "sh",
	.SW = "sw",
	.ADDI = "addi",
	.SLTI = "slti",
	.SLTIU = "sltiu",
	.XORI = "xori",
	.ORI = "ori",
	.ANDI = "andi",
	.SLLI = "slli",
	.SRLI = "srli",
	.SRAI = "srai",
	.ADD = "add",
	.SUB = "sub",
	.SLL = "sll",
	.SLT = "slt",
	.SLTU = "sltu",
	.XOR = "xor",
	.SRL = "srl",
	.SRA = "sra",
	.OR = "or",
	.AND = "and",
	.FENCE = "fence",
	.ECALL = "ecall",
	.EBREAK = "ebreak"
};

@static
register_abi_names := map[Reg]string{
	.X0 = "zero",
	.X1 = "ra",
	.X2 = "sp",
	.X3 = "gp",
	.X4 = "tp",
	.X5 = "t0",
	.X6 = "t1",
	.X7 = "t2",
	.X8 = "s0",
	.X9 = "s1",
  .X10 = "a0",
	.X11 = "a1",
	.X12 = "a2",
	.X13 = "a3",
	.X14 = "a4",
	.X15 = "a5",
	.X16 = "a6",
	.X17 = "a7",
	.X18 = "s2",
	.X19 = "s3",
	.X20 = "s4",
	.X21 = "s5",
	.X22 = "s6",
	.X23 = "s7",
	.X24 = "s8",
	.X25 = "s9",
	.X26 = "s10",
	.X27 = "s11",
	.X28 = "t3",
	.X29 = "t4",
	.X30 = "t6",
	.X31 = "t7",
};


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
			instr.imm = u_immediate(ibits);
		case 0x17:
			instr.op = .AUIPC;
			instr.rd = rd(ibits);
			instr.imm = u_immediate(ibits);
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
				if(sh.addr + sh.size > cast(u32)len(buffer)) {
					fmt.eprint("RAM_SIZE too small to load this section\n");
					return false;
				} else {
					mem.copy(&buffer[sh.addr], &elf_file.data[sh.offset], int(sh.size));
				}
			case ".bss":
				if(sh.addr + sh.size > cast(u32)len(buffer)) {
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




print_instruction_att :: proc(instr: Instruction) {
	fmt.printf("%s", opcode_names[instr.op]);

	switch instr.op {
		case .LUI, .AUIPC, .JAL:
			fmt.printf("\t%s,%d", register_abi_names[instr.rd], instr.imm);
		case .JALR:
			fmt.printf("\t%s,%s,%d", 
				register_abi_names[instr.rd],
				register_abi_names[instr.rs1],
				instr.imm);
		case .BEQ, .BNE, .BLT, .BGE, .BLTU, .BGEU:
			fmt.printf("\t%s,%s(%d)",
				register_abi_names[instr.rs1],
				register_abi_names[instr.rs2],
				instr.imm);
		case .LB, .LH, .LW, .LBU, .LHU:
			fmt.printf("\t%s, %d(%s)",
				register_abi_names[instr.rd],
				instr.imm,
				register_abi_names[instr.rs1]);
		case .SB, .SH, .SW:
			fmt.printf("\t%s,%d(%s)",
				register_abi_names[instr.rd],
				instr.imm,
				register_abi_names[instr.rs1]);
		case .ADDI, .SLTI, .SLTIU, .XORI, .ORI, .ANDI,
				 .SLLI, .SRLI, .SRAI:
			fmt.printf("\t%s,%s,%d",
				register_abi_names[instr.rd],
				register_abi_names[instr.rs1],
				instr.imm);
		case .ADD, .SUB, .SLL, .SLT, .SLTU, .XOR, .SRL,
				 .SRA, .OR, .AND:
			fmt.printf("\t%s,%s,%s",
				register_abi_names[instr.rd],
				register_abi_names[instr.rs1],
				register_abi_names[instr.rs2]);
		case .FENCE, .ECALL, .EBREAK:
			fmt.print("\tSYSCALL INSTRUCTION");		
	}
}




disassemble :: proc(elf_file: ^elf.Elf32_File) {
	for _, sh_index in elf_file.section_headers {
		sh := &elf_file.section_headers[sh_index];
		if elf.lookup_section_name(elf_file, sh) == ".text" {
			fmt.println("Disassembly of section .text:\n");

			slice := elf_file.data[sh.offset : sh.size + sh.offset];
			words := mem.slice_data_cast([]u32, slice);
			for word, i in words {
				instr, ok := decode(word);
				if (ok) {
					address := u32(i * 4) + sh.addr;

					sym := elf.global_sym_by_address(elf_file, address, u16(sh_index));
					if(sym != nil) {
						fmt.printf("\n%x <%s>\n", address, elf.sym_name(elf_file, sym));
					}
					fmt.printf("%8x:\t%8x\t\t", address, word); 
					print_instruction_att(instr);
					fmt.println();
				}
			}
			break;
		}
	}
}




init :: proc(cpu: ^CPU, ram_size: uint) {
	cpu^ = CPU{};
	cpu.registers[Reg.X2] = i32(ram_size); // initialize stack pointer to top of memory
	cpu.ram = make([]byte, ram_size);
}


read_reg :: proc(cpu: ^CPU, reg: Reg) -> i32 {
	return reg == .X0 ? 0 : cpu.registers[reg];
}

write_reg :: proc(cpu: ^CPU, reg: Reg, value: i32) {
	if (reg != .X0) {
		cpu.registers[reg] = value;
	}
}

read_word :: proc(cpu: ^CPU, address: u32) -> u32 {
	byte_ptr := &cpu.ram[address];
	word_ptr := cast(^u32)byte_ptr;
  return word_ptr^;
}

store_word :: proc(cpu: ^CPU, address: u32, word: u32) {
	byte_ptr := &cpu.ram[address];
	word_ptr := cast(^u32)byte_ptr;
	word_ptr^ = word;
}


execute :: proc(cpu: ^CPU, instr: Instruction) -> bool {
	jumped := false;

	if(cpu.pc & 0x3 != 0) {
		fmt.eprintf("0x%8x: illegal fetch of misaligned address");
	}

	switch(instr.op) {
		case .LUI:
			write_reg(cpu, instr.rd, instr.imm);
		case .AUIPC:
			write_reg(cpu, instr.rd, instr.imm + i32(cpu.pc));
			return false;
		case .JAL:
			write_reg(cpu, instr.rd, i32(cpu.pc + 4));
			fmt.printf("\tJAL immediate: %d\n", instr.imm);
			cpu.pc += u32(instr.imm);
			fmt.printf("\tnew pc: %d", cpu.pc);
			jumped = true;
		case .JALR:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
		case .BEQ:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
		case .BNE:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
		case .BLT:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
		case .BGE:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
		case .BLTU:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
		case .BGEU:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
		case .LB:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
		case .LH:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
		case .LW:
			address := u32(read_reg(cpu, instr.rs1) + instr.imm);
			write_reg(cpu, instr.rd, cast(i32)read_word(cpu, address));
		case .LBU:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
		case .LHU:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
		case .SB:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
		case .SH:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
		case .SW:
			address := u32(read_reg(cpu, instr.rs1) + instr.imm);
			store_word(cpu, address, cast(u32)read_reg(cpu, instr.rd));
		case .ADDI:
			//ensure that odin addition semantics match ADDI
			write_reg(cpu, instr.rd, cpu.registers[instr.rs1] + instr.imm);
		case .SLTI:
			write_reg(cpu, instr.rd, read_reg(cpu, instr.rs1) < instr.imm ? 1 : 0);
		case .SLTIU:
			write_reg(cpu, instr.rd, read_reg(cpu, instr.rs1) < instr.imm ? 1 : 0);
		case .XORI:
			write_reg(cpu, instr.rd, read_reg(cpu, instr.rs1) ~ instr.imm);
		case .ORI:
			write_reg(cpu, instr.rd, read_reg(cpu, instr.rs1) | instr.imm);
		case .ANDI:
			write_reg(cpu, instr.rd, read_reg(cpu, instr.rs1) & instr.imm);
		case .SLLI:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
		case .SRLI:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
		case .SRAI:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
		case .ADD:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
		case .SUB:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
		case .SLL:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
		case .SLT:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
		case .SLTU:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
		case .XOR:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
		case .SRL:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
		case .SRA:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
		case .OR:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
		case .AND:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
		case .FENCE:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
		case .ECALL:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
		case .EBREAK:
			fmt.eprintf("0x%8x: %s not yet implemented\n", cpu.pc, opcode_names[instr.op]);
			return false;
	}

	if !jumped {
		cpu.pc += 4;
	}
	return true;
}




main :: proc() {



	if(len(os.args) < 2) {
		fmt.eprint("Usage: loader [PATH_TO_ELF_FILE].elf");
		os.exit(1);
	}

	cpu: CPU;
	init(&cpu, 1024 * 1024);

	file_bytes, success := os.read_entire_file(os.args[1]);
	if (!success) {
		fmt.eprint("Error opening ELF file");
		os.exit(1);
	}


	elf_file: elf.Elf32_File = elf.parse(file_bytes);
	//elf.print_report(&elf_file);
	ok := load(cpu.ram, &elf_file);
	if(!ok) {
		fmt.eprint("Error loading program");
		os.exit(1);
	}
	disassemble(&elf_file);

	startsym := elf.lookup_symbol_by_name(&elf_file, "_start");
	if(startsym == nil) {
		fmt.eprintf("No start symbol defined! Exiting . . .");
		os.exit(1);
	}
	cpu.pc = startsym.value;
	
	
	fmt.print("\n\n==============================\n");
	fmt.println("Executing!!");
	//execute loop
	for {
		word : u32 = (cast(^u32)(&cpu.ram[cpu.pc]))^;
		instr, ok := decode(word);
		if !ok {
			fmt.eprintf("decoding error at 0x%x!\n", cpu.pc);
			break;
		}
		
		fmt.print("Executing ");
		print_instruction_att(instr);
		fmt.println();
		res := execute(&cpu, instr);
		if !res {
			fmt.eprintln("execution error!");
			break;
		}
	}
}