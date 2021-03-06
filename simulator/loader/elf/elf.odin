package elf

import "core:mem"
import "core:fmt"


//Elf file types
ET_NONE   :: 0x0000;
ET_REL    :: 0x0001;
ET_EXEC   :: 0x0002;
ET_DYN    :: 0x0003;
ET_CORE   :: 0x0004;
ET_LOOS   :: 0xfe00;
ET_HIOS   :: 0xfeff;
ET_LOPROC :: 0xff00;
ET_HIPROC :: 0xffff;

@static
elf_file_type_descriptions := map[u16]string {
  ET_NONE   = "None",
  ET_REL    = "Relocatable",
  ET_EXEC   = "Executable",
  ET_DYN    = "Dynamically Linkable Library",
  ET_CORE   = "Core File",
  ET_LOOS   = "LOOS",
  ET_HIOS   = "HIOS",
  ET_LOPROC = "LOPROC",
  ET_HIPROC = "HIPROC"
};


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

@static
ph_type_descriptions := map[u32]string{
  PT_NULL =    "Null",
  PT_LOAD =    "Loadable Segment",
  PT_DYNAMIC = "Dynamic Linking Information",
  PT_INTERP =  "Interpreter Information",
  PT_NOTE =    "Auxiliary Information",
  PT_SHLIB =   "RESERVED",
  PT_PHDR =    "Program Header",
  PT_LOOS =    "OS Specific",
  PT_HIOS =    "OS Specific",
  PT_LOPROC =  "Processor Specific",
  PT_HIPROC =  "Processor Specific",
};

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

@static
sh_type_descriptions := map[u32]string{
  SHT_NULL = "NULL",
  SHT_PROGBITS = "Program Data",
  SHT_SYMTAB = "Symbol Table",
  SHT_STRTAB = "String Table",
  SHT_RELA = "Relocation Entries (with addrends)",
  SHT_HASH = "Symbol Hash Table",
  SHT_DYNAMIC = "Dynamic Linking Info",
  SHT_NOTE = "Notes",
  SHT_NOBITS = "Program Space with no Data (BSS)",
  SHT_REL = "Relocation Entries",
  SHT_SHLIB = "RESERVED",
  SHT_DYNSYM = "Dynamic Linker Symbol Table",
  SHT_INIT_ARRAY = "Array of Constructors",
  SHT_FINI_ARRAY = "Array of Destructors",
  SHT_PREINIT_ARRAY = "Array of Preconstructors",
  SHT_GROUP = "Section Group",
  SHT_SYMTAB_SHNDX = "Extended Setion Indices",
  SHT_NUM = "Number of Defined Types",
  SHT_LOOS = "SHT_LOOS"
};


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





//symbol table constants

//symbol binding
STB_LOCAL     :: 0;
STB_GLOBAL    :: 1;
STB_WEAK      :: 2;
STB_LOOS      :: 10;
STB_HIOS      :: 12;
STB_LOPROC    :: 13;
STB_HIPROC    :: 15;

@static
symbol_bind_descriptions := map[byte]string{
  STB_LOCAL  = "LOCAL",
  STB_GLOBAL = "GLOBAL",
  STB_WEAK   = "WEAK",
};


//symbol type
STT_NOTYPE  :: 0;
STT_OBJECT  :: 1;
STT_FUNC    :: 2;
STT_SECTION :: 3;
STT_FILE    :: 4;
STT_COMMON  :: 5;
STT_TLS     :: 6;
STT_LOOS    :: 10;
STT_HIOS    :: 12;
STT_LOPROC  :: 13;
STT_HIPROC  :: 15;

@static
symbol_type_descriptions := map[byte]string{
  STT_NOTYPE  = "NOTYPE",
  STT_OBJECT  = "OBJECT",
  STT_FUNC    = "FUNC",
  STT_SECTION = "SECTION",
  STT_FILE    = "FILE",
  STT_COMMON  = "COMMON",
  STT_TLS     = "TLS",
};


//symbol visibility
STV_DEFAULT   :: 0;
STV_INTERNAL  :: 1;
STV_HIDDEN    :: 2;
STV_PROTECTED :: 3;

@static
symbol_vis_descriptions := map[byte]string{
  STV_DEFAULT   = "DEFAULT",
  STV_INTERNAL  = "INTERNAL",
  STV_HIDDEN    = "HIDDEN",
  STV_PROTECTED = "PROTECTED"
};



Elf32_Ehdr :: struct #packed {
  ident: [EI_NIDENT]u8,
  type: u16,
  machine: u16,
  version: u32,
  entry: u32,
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
  addr: u32,  //virtual address in final executable
  offset: u32,
  size: u32,
  link: u32,
  info: u32,
  addralign: u32,
  entsize: u32
};



Elf32_Sym :: struct #packed {
  name: u32,
  value: u32,
  size: u32,
  info: byte,
  other: byte,
  shndx: u16  //index of the section that this symbol is defined in
};

sym_visibility :: proc(sym: ^Elf32_Sym) -> byte {
  return sym.other & 0x3;
}

sym_bind :: proc(sym: ^Elf32_Sym) -> byte {
  return sym.info >> 4;
}

sym_type :: proc(sym: ^Elf32_Sym) -> byte {
  return sym.info & 0xf;
}


Elf32_File :: struct {
  data: []byte,
  file_header: Elf32_Ehdr,
  program_headers: [dynamic]Elf32_Phdr,  //TODO: make these normal slices?
  section_headers: [dynamic]Elf32_Shdr,  //TODO: make these normal slices?
};



error_msg : string : "No error";


parse :: proc(elf_file_bytes: []byte) -> Elf32_File {
  elf_file: Elf32_File;

  elf_file.data = elf_file_bytes;
  mem.copy(&elf_file.file_header, &elf_file_bytes[0], size_of(Elf32_Ehdr));

  //program headers
  for i in 0..<elf_file.file_header.phnum {
    program_header: Elf32_Phdr;
    mem.copy(&program_header, 
         &elf_file_bytes[elf_file.file_header.phoff + u32(elf_file.file_header.phentsize * i)],
         int(elf_file.file_header.phentsize));
    append(&elf_file.program_headers, program_header);
  }


  //section headers
  for i in 0..<elf_file.file_header.shnum {
    section_header: Elf32_Shdr;
    mem.copy(&section_header,
         &elf_file_bytes[elf_file.file_header.shoff + u32(elf_file.file_header.shentsize * i)],
             int(elf_file.file_header.shentsize));
    append(&elf_file.section_headers, section_header);
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
      fmt.print("Size:32 bits\n");
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
  type_descr, ok := elf_file_type_descriptions[type];
  if(!ok) {
    type_descr = "UNKNOWN";
  }
  fmt.printf("Type: %s\n", type_descr);

  //machine
  fmt.print("Instruction Set Architecture: ");
  switch machine {
    case EM_RISCV:
      fmt.print("RISC-V\n");
    case:
      fmt.print("Unknown\n");
  }

  fmt.printf("Entry: %d\n", entry);
  fmt.printf("Flags: %x\n", flags);
  fmt.printf("Section Header Symbol Table Index: %d\n", shstrndx);
}


print_program_header :: proc(program_header: Elf32_Phdr) {
  using program_header;
  type_descr, ok := ph_type_descriptions[type];
  if(!ok) {
    type_descr = "UNKOWN TYPE";
  }
  fmt.printf("Type: %s\n", type_descr);
  fmt.printf("offset: %d\n", offset);
  fmt.printf("virtual address: %d\n", vaddr);
  fmt.printf("physical address: %d\n", paddr);
  fmt.printf("file size: %d\n", filesz);
  fmt.printf("mem size: %d\n", memsz);
  fmt.printf("flags: %d\n", flags);
  fmt.printf("align: %d\n", align);
}


lookup_section_name :: proc(elf_file: ^Elf32_File, section_header: ^Elf32_Shdr) -> string {
  string_table_header: Elf32_Shdr = elf_file.section_headers[elf_file.file_header.shstrndx];
  string_index := string_table_header.offset + section_header.name;
  cs := cast(cstring)&elf_file.data[string_index];
  return cast(string)cs;
}



sym_name :: proc(elf_file: ^Elf32_File, symbol: ^Elf32_Sym) -> string {
  
  if symbol.name == 0 {
    return "UNNAMED";
  }
  
  string_table_header: ^Elf32_Shdr;

  for _, i in elf_file.section_headers {
    sh := &elf_file.section_headers[i];
    if lookup_section_name(elf_file, sh) == ".strtab" {
      string_table_header = sh;
      break;
    }
  }

  string_index := string_table_header.offset + symbol.name;
  cs := cast(cstring)&elf_file.data[string_index];
  return cast(string)cs;
}


lookup_symbol_by_name :: proc(elf_file: ^Elf32_File, name: string) -> ^Elf32_Sym {
  symtab_header := symbol_table(elf_file);
  sym_count := symtab_header.size / symtab_header.entsize;
  for i in 0..<sym_count {
    sym := cast(^Elf32_Sym) &elf_file.data[symtab_header.offset + i * symtab_header.entsize];
    if sym_name(elf_file, sym) == name {
      return sym;
    }
  }
  return nil;
}



symbol_table :: proc(elf_file: ^Elf32_File) -> ^Elf32_Shdr {
  for _, i in elf_file.section_headers {
    sh := &elf_file.section_headers[i];
    if lookup_section_name(elf_file, sh) == ".symtab" {
      return sh; 
    }
  }
  return nil;
}



//SLOW AND UNWIELDY?
global_sym_by_address :: proc(elf_file: ^Elf32_File, address: u32, sh_hdr_index: u16) -> ^Elf32_Sym {
  
  symtab_header := symbol_table(elf_file);
  sym_count := symtab_header.size / symtab_header.entsize;
  for i in 0..<sym_count {
    sym := cast(^Elf32_Sym) &elf_file.data[symtab_header.offset + i * symtab_header.entsize];
    if sym.value == address && sym_bind(sym) == STB_GLOBAL {
      return sym;
    }
  }
  return nil;
}











print_section_header :: proc(elf_file: ^Elf32_File, section_header: ^Elf32_Shdr) {
  using section_header;
  fmt.printf("name: %s\n", lookup_section_name(elf_file, section_header));

  type_descr, ok := sh_type_descriptions[type];
  if(!ok) {
    type_descr = "UNKNOWN TYPE";
  }
  fmt.printf("type: %s\n", type_descr);
  fmt.printf("flags: 0x%x\n", flags);
  fmt.printf("virtual address: 0x%x\n", addr);
  fmt.printf("offset: 0x%x\n", offset);
  fmt.printf("size: 0x%x\n", size);
  fmt.printf("link: %d\n", link);
  fmt.printf("info: %d\n", info);
  fmt.printf("addralign: %d\n", addralign);
  fmt.printf("entsize: %d\n", entsize);
}


print_symbols :: proc(elf_file: ^Elf32_File, symtab_header: ^Elf32_Shdr) {
  sym_count := symtab_header.size / symtab_header.entsize;
  fmt.printf("%10s %10s %10s %10s %5s %10s %20s\n", 
    "Value", 
    "Size", 
    "Bind", 
    "Vis", 
    "Ndx", 
    "Section", 
    "Name");

  for i in 0..<sym_count {
    sym := cast(^Elf32_Sym) &elf_file.data[symtab_header.offset + i * symtab_header.entsize];
    fmt.printf("%8x:  %10x %10s %10s %5d %10s %20s\n", 
      sym.value,
      sym.size,
      symbol_bind_descriptions[sym_bind(sym)],
      symbol_vis_descriptions[sym_visibility(sym)],
      sym.shndx,
      "SECTION",
      sym_name(elf_file, sym));
  }
  fmt.print("\n\n");
}


print_report :: proc(elf_file: ^Elf32_File) {
  print_header(elf_file.file_header);
  fmt.print("\n\n");

  

  fmt.printf("Program Header Entries: %d (starts at 0x%x), size: %d bytes\n\n",
         elf_file.file_header.phnum,
         elf_file.file_header.phoff,
         elf_file.file_header.phentsize);
  for header in elf_file.program_headers {
    print_program_header(header);
    fmt.print("\n\n");
  }
  fmt.printf("Section Header Entries: %d (starts at 0x%x), size: %d bytes\n\n", 
        elf_file.file_header.shnum,
        elf_file.file_header.shoff,
        elf_file.file_header.shentsize);

  for _, i in elf_file.section_headers {
    header := &elf_file.section_headers[i];
    print_section_header(elf_file, header);
    fmt.printf("\n\n");
  }

  //print symbol table
  symtab_header := symbol_table(elf_file);
  fmt.printf("Symbol Table Entries: %d\n\n", symtab_header.entsize);
  print_symbols(elf_file, symtab_header);

}