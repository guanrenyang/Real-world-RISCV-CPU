#include <common.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <elf.h>

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
        panic("open elf file failed");
    }
    
    /* map the elf file into a continuous memory space*/
    if ((map = mmap(NULL, lseek(fd, 0, SEEK_END), PROT_READ, MAP_PRIVATE, fd, 0)) == MAP_FAILED) {
        panic("mmap elf file failed");
    }

    ehdr = (Elf32_Ehdr *)map;
    shdr = (Elf32_Shdr *)(map + ehdr->e_shoff);
    
    /* Find the string table section*/
    int i;
    strtab = NULL;
    for (i = 0; i < ehdr->e_shnum; i++) {
        if (shdr[i].sh_type == SHT_STRTAB) {
            strtab_size = shdr[i].sh_size;

            strtab = malloc(strtab_size);
            memcpy(strtab, map + shdr[i].sh_offset, strtab_size);
            break;
        }
    }

    int j;
    symtab = NULL;
    for (j = 0; j < ehdr->e_shnum; j++) {
        if (shdr[j].sh_type == SHT_SYMTAB) {
            symtab_size = shdr[j].sh_size;

            symtab = malloc(symtab_size);
            memcpy(symtab, map + shdr[j].sh_offset, symtab_size);
            break;
        }
    }
    
    /* print the strtab*/
    Log("strtab: ");
    for (int i = 0; i < strtab_size; i++) {
        printf("%x ", strtab[i]);
    }
    printf("\n");

    /* print the symtab*/
    Log("symtab: ");
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

bool is_func(vaddr_t addr){
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
void source_func_name(vaddr_t addr, char* func_name){
    // to determine which function the address `addr` belongs to
    Elf32_Sym *sym = (Elf32_Sym *)symtab;
    int i;
    for (i = 0; i < symtab_size / sizeof(Elf32_Sym); i++) {
        if (ELF32_ST_TYPE(sym[i].st_info) == STT_FUNC) {
            if (addr >= sym[i].st_value && addr < sym[i].st_value + sym[i].st_size) {
                // return the function name
                Log("function name: %s", strtab + sym[i].st_name);
                strcpy(func_name, strtab + sym[i].st_name);
                return;
            }
        }
    }
}

void source_func_addr(vaddr_t addr, vaddr_t* func_addr) {
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
    panic("not in a function");
}