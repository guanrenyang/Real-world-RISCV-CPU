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
        printf("%c", strtab[i]);
    }
    printf("\n");

    /* print the symtab*/
    Log("symtab: ");
    for (int i = 0; i < symtab_size; i++) {
        printf("%c", symtab[i]);
    }
    printf("\n");
   
    munmap(map, lseek(fd, 0, SEEK_END));
    close(fd);
}