package elf

import "core:mem"
import "core:fmt"


//Elf file types
ET_NONE   :: 0;
ET_REL    :: 1;
ET_EXEC   :: 2;
ET_DYN    :: 3;
ET_CORE   :: 4;
ET_LOOS   :: 0xfe00;
ET_HIOS   :: 0xfeff;
ET_LOPROC :: 0xff00;
ET_HIPROC :: 0xffFF;



//EI 
EI_MAG0       :: 0;
EI_MAG1       :: 1;
EI_MAG2       :: 2;
EI_MAG3       :: 3;
EI_CLASS      :: 4;
EI_DATA       :: 5;
EI_VERSION    :: 6;
EI_OSABI      :: 7;
EI_ABIVERSION :: 8;
EI_PAD        :: 9;
EI_NIDENT     :: 16;

//Elf machine types
EM_RISCV :: 0xf3;



//Program Header types
PT_NULL    :: 0x00000000;
PT_LOAD    :: 0x00000001;
PT_DYNAMIC :: 0x00000002;
PT_INTERP  :: 0x00000003;
PT_NOTE    :: 0x00000004;
PT_SHLIB   :: 0x00000005;
PT_PHDR    :: 0x00000006;
PT_LOOS    :: 0x60000000;
PT_HIOS    :: 0x6FFFFFFF;
PT_LOPROC  :: 0x70000000;
PT_HIPROC  :: 0x7FFFFFFF;	


//Section Header types
SHT_NULL          :: 0x0;
SHT_PROGBITS      :: 0x1;
SHT_SYMTAB        :: 0x2;
SHT_STRTAB        :: 0x3;
SHT_RELA          :: 0x4;
SHT_HASH          :: 0x5;
SHT_DYNAMIC       :: 0x6;
SHT_NOTE          :: 0x7;
SHT_NOBITS        :: 0x8;
SHT_REL           :: 0x9;
SHT_SHLIB         :: 0x0A;
SHT_DYNSYM        :: 0x0B;
SHT_INIT_ARRAY    :: 0x0E;
SHT_FINI_ARRAY    :: 0x0F;
SHT_PREINIT_ARRAY :: 0x10;
SHT_GROUP         :: 0x11;
SHT_SYMTAB_SHNDX  :: 0x12;
SHT_NUM           :: 0x13;
SHT_LOOS          :: 0x60000000;


//Section Header flags
SHF_WRITE            :: 0x1;
SHF_ALLOC            :: 0x2;
SHF_EXECINSTR        :: 0x4;
SHF_MERGE            :: 0x10;
SHF_STRINGS          :: 0x20;
SHF_INFO_LINK        :: 0x40;
SHF_LINK_ORDER       :: 0x80;
SHF_OS_NONCONFORMING :: 0x100;
SHF_GROUP            :: 0x200;
SHF_TLS              :: 0x400;
SHF_MASKOS           :: 0x0ff00000;
SHF_MASKPROC         :: 0xf0000000;
SHF_ORDERED          :: 0x4000000;
SHF_EXCLUDE          :: 0x8000000;


Elf32_Ehdr :: struct #packed {
	ident: [EI_NIDENT]u8,
	type: u16,
	machine: u16,
	version: u32,
	entry: u32, // make this into a pointer type? but maybe not since
			    // we're compiling this on a 64 bit machine and we're
			    // targeting 32 bit elf files
	phoff: u32,
	shoff: u32,
	flags: u32,
	ehsize: u16,
	phentsize: u16,
	phnum: u16,
	shentsize: u16,
	shnum: u16,
	shstrndx: u16
};



Elf32_Phdr :: struct #packed {
	type: u32,
	offset: u32,
	vaddr: u32,
	paddr: u32,
	filesz: u32,
	memsz: u32,
	flags: u32,
	align: u32,
};


Elf32_Shdr :: struct #packed {
	name: u32,
	type: u32,
	flags: u32,
	addr: u32,
	offset: u32,
	size: u32,
	link: u32,
	info: u32,
	addralign: u32,
	entsize: u32
};



Elf32_File :: struct {
	file_header: Elf32_Ehdr,
	program_headers: [dynamic]Elf32_Phdr, //TODO, make these normal slices?
	section_headers: [dynamic]Elf32_Shdr //TODO, make these normal slices?
};



error_msg : string : "No error";


parse :: proc(elf_file_bytes: []byte) -> Elf32_File {
	elf_file: Elf32_File;

	mem.copy(&elf_file.file_header, &elf_file_bytes[0], size_of(Elf32_Ehdr));

	for i in 0..<elf_file.file_header.phnum {
		program_header: Elf32_Phdr;
		mem.copy(&program_header, 
				 &elf_file_bytes[elf_file.file_header.phoff + u32(elf_file.file_header.phentsize * i)],
				 int(elf_file.file_header.phentsize));
		append(&elf_file.program_headers, program_header);
	}

	return elf_file;
}



print_header :: proc(elf_header: Elf32_Ehdr) {
	using elf_header;

	//begin ident
	if(ident[EI_MAG0] == 127 &&
	   ident[EI_MAG1] == 'E' &&
	   ident[EI_MAG2] == 'L' &&
	   ident[EI_MAG3] == 'F') {
		fmt.print("Signature correct.  We're dealing with an ELF file over here\n");
	} else {
		fmt.print("Signature incorrect. Do you even ELF?\n");
		return;
	}

	switch ident[EI_CLASS] {
		case 1:
			fmt.print("Size: 32 bits\n");
		case 2:
			fmt.print("Size: 64 bits\n");
		case:
			fmt.print("Unknown size code: %d", ident[EI_CLASS]);
	}

	switch ident[EI_DATA] {
		case 1:
			fmt.print("Endianness: Little\n");
		case 2:
			fmt.print("Endianness: big\n");
		case:
			fmt.print("Unknown Endianness code: %d", ident[EI_DATA]);
	}

	fmt.printf("Current Version: %d\n", ident[EI_VERSION]);
	fmt.printf("ABI: %d\n", ident[EI_OSABI]);
	fmt.printf("ABI version: %d\n", ident[EI_ABIVERSION]);
	//end ident

	//type
	fmt.print("Type: ");
	switch type {
		case ET_NONE:
			fmt.print("None\n");
		case ET_REL:
			fmt.print("Relocatable File\n");
		case ET_EXEC:
			fmt.print("Executable\n");			
		case ET_DYN:
			fmt.print("Dynamically Linkable Library\n");
		case ET_CORE:
			fmt.print("Core File\n");
		case ET_LOOS:
			fmt.print("LOOS (?)\n");
		case ET_HIOS:
			fmt.print("HIOS (?)\n");
		case ET_LOPROC:
			fmt.print("LOPROC (?)\n");			
		case ET_HIPROC:
			fmt.print("HIPROC (?)\n");
	}

	//machine
	fmt.print("Instruction Set Architecture: ");
	switch machine {
		case EM_RISCV:
			fmt.print("RISC-V\n");
		case:
			fmt.print("Unknown\n");
	}

	fmt.printf("Entry: %d\n", entry);
	fmt.printf("Program Header Entries: %d (starts at 0x%x), size: %d bytes\n", phnum, phoff, phentsize);
	fmt.printf("Section Header Entries: %d (starts at 0x%x), size: %d bytes\n", shnum, shoff, shentsize);
}

print_report :: proc(elf_file: Elf32_File) {
	print_header(elf_file.file_header);

	fmt.print("\n\n\n");
	fmt.print("Program Headers");
	fmt.print("\n\n\n");

	for i in 0..<len(elf_file.program_headers) {
		fmt.print(elf_file.program_headers[i]);
		fmt.print("\n\n");
	}
}

