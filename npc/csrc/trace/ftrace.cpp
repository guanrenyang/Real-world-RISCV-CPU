#include <trace.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <elf.h>
#include <assert.h>
#include <trace.h>

char *strtab, *symtab;
size_t strtab_size, symtab_size;  

void init_elf(const char *elf_file){
/*read the `elf_file` and extract the symbol table and string table*/
    int fd;
    void *map;
    Elf32_Ehdr *ehdr;
    Elf32_Shdr *shdr;

    /* open the elf file*/
    if ((fd = open(elf_file, O_RDONLY)) < 0) {
        printf("open elf file failed");
		exit(0);
    }
    
    /* map the elf file into a continuous memory space*/
    if ((map = mmap(NULL, lseek(fd, 0, SEEK_END), PROT_READ, MAP_PRIVATE, fd, 0)) == MAP_FAILED) {
        printf("mmap elf file failed");
		exit(0);
    }

    ehdr = (Elf32_Ehdr *)map;
    shdr = (Elf32_Shdr *)(map + ehdr->e_shoff);
    
    /* Find the string table section*/
    int i;
    strtab = NULL;
    for (i = 0; i < ehdr->e_shnum; i++) {
        if (shdr[i].sh_type == SHT_STRTAB) {
            strtab_size = shdr[i].sh_size;

            strtab = (char *)malloc(strtab_size);
            memcpy(strtab, map + shdr[i].sh_offset, strtab_size);
            break;
        }
    }

    int j;
    symtab = NULL;
    for (j = 0; j < ehdr->e_shnum; j++) {
        if (shdr[j].sh_type == SHT_SYMTAB) {
            symtab_size = shdr[j].sh_size;

            symtab = (char *)malloc(symtab_size);
            memcpy(symtab, map + shdr[j].sh_offset, symtab_size);
            break;
        }
    }
    
    /* print the strtab*/
    printf("strtab: ");
    for (int i = 0; i < strtab_size; i++) {
        printf("%x ", strtab[i]);
    }
    printf("\n");

    /* print the symtab*/
    printf("symtab: ");
    for (int i = 0; i < symtab_size; i++) {
        printf("%x ", symtab[i]);
    }
    printf("\n");
   
    munmap(map, lseek(fd, 0, SEEK_END));
    close(fd);
}

void clear_elf(){
/* release the memory used to store the symbol table and string table*/
    free(strtab);
    free(symtab);
}

bool is_func(uint32_t addr){
    // to determine which function the address `addr` belongs to
    Elf32_Sym *sym = (Elf32_Sym *)symtab;
    int i;
    for (i = 0; i < symtab_size / sizeof(Elf32_Sym); i++) {
        if (ELF32_ST_TYPE(sym[i].st_info) == STT_FUNC) {
            if (addr == sym[i].st_value) {
                // return the function name
                // Log("function name: %s", strtab + sym[i].st_name);
                return true;
            }
        }
    }
    
    return false;
}
void source_func_name(uint32_t addr, char* func_name){
    // to determine which function the address `addr` belongs to
    Elf32_Sym *sym = (Elf32_Sym *)symtab;
    int i;
    for (i = 0; i < symtab_size / sizeof(Elf32_Sym); i++) {
        if (ELF32_ST_TYPE(sym[i].st_info) == STT_FUNC) {
            if (addr >= sym[i].st_value && addr < sym[i].st_value + sym[i].st_size) {
                // return the function name
                // Log("function name: %s", strtab + sym[i].st_name);
                strcpy(func_name, strtab + sym[i].st_name);
                return;
            }
        }
    }
}

void source_func_addr(uint32_t addr, uint32_t* func_addr) {
    Elf32_Sym *sym = (Elf32_Sym *)symtab;
    int i;
    for (i = 0; i < symtab_size / sizeof(Elf32_Sym); i++) {
        if (ELF32_ST_TYPE(sym[i].st_info) == STT_FUNC) {
            if (addr >= sym[i].st_value && addr < sym[i].st_value + sym[i].st_size) {
                // return the function name
                // Log("function name: %s", strtab + sym[i].st_name);
                *func_addr = sym[i].st_value;
                return;
            }
        }
    }
    printf("not in a function\n");
	//assert(0);
}

enum JumpType {JAL, JALR, OTHER}; 
bool is_jump(uint32_t inst){ 
	// to determine whether the riscv32 instruction `inst` is a jump instruction 
	uint32_t opcode = inst & 0x7f;	
	uint32_t funct3 = (inst >> 12) & 0x7;
	if (opcode == 0x6f) // jal
		return true;
	if (opcode = 0x67 && funct3 == 0x0) // jalr
		return true;

	return false;
}

int get_jump_type(uint32_t inst){
	uint32_t opcode = inst & 0x7f;	
	uint32_t funct3 = (inst >> 12) & 0x7;
	if (opcode == 0x6f) // jal
		return JAL;
	if (opcode = 0x67 && funct3 == 0x0) // jalr
		return JALR;
	
	return OTHER;
}

/* DPI-C to get the `dnpc`, `pc`*/
void ftrace_parse_inst(uint32_t inst, int *rd, int *rs1){
	// to parse the riscv32 instruction `inst` and get the `dnpc` and `pc`
	(*rd) = (inst >> 7) & 0x1f;
	(*rs1) = (inst >> 15) & 0x1f;
}

char INDENT[1000] = "";
void ftrace(uint32_t inst, uint32_t dnpc, uint32_t pc){
  int type = get_jump_type(inst);

  int rd = (inst >> 7) & 0x1f;
  int rs1 = (inst >> 15) & 0x1f;

  char curr_func_name[30];
  char func_name[30];
  uint32_t func_addr;

  source_func_name(pc, curr_func_name);
  source_func_name(dnpc, func_name);
  source_func_addr(dnpc, &func_addr);

  char message[2000];
  if (type==JALR && rd==0 && rs1==1) {
    //Log("Ret: %s(%x)", func_name, addr);
    sprintf(message, "%x: ", pc);
    strcat(message, INDENT);
    strcat(message, "Ret to %s(%x) from %s(%x);\n");
    printf(message, func_name, dnpc, curr_func_name, pc);
    //if(strlen(INDENT)>2)
    assert(strlen(INDENT)>2);
    INDENT[strlen(INDENT)-2] = '\0';
  } else if (is_func(dnpc)){
    strcat(INDENT, "  ");

    sprintf(message, "%x: ", pc);
    strcat(message, INDENT);
    strcat(message, "Call %s(%x);\n");
    printf(message, func_name, dnpc);
  }
}