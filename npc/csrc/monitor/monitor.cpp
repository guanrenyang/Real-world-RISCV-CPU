#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include <paddr.h>
#include <npc.h>

char *log_file = NULL;
char *img_file = NULL;
char *elf_file = NULL;
char *diff_so_file = NULL;


void init_mem();
void init_log(const char *);
void init_elf(const char *); 
void init_disasm(const char *triple);
void init_difftest(char *ref_so_file, long img_size, int port);

static long load_img(){
  if (img_file == NULL) {
    printf("No image is given. Use the default build-in image.");
    return 4096; // built-in image size
  }

  FILE *fp = fopen(img_file, "rb");
  // Assert(fp, "Can not open '%s'", img_file);

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);
  
  fseek(fp, 0, SEEK_SET); 
  int ret = fread(guest_to_host(RESET_VECTOR), size, 1, fp);
  assert(ret != 0);

  fclose(fp);
  return size;
}

static int parse_args(int argc, char *argv[]) {
  const struct option table[] = {
    {"log"      , required_argument, NULL, 'l'},
	{"diff"     , required_argument, NULL, 'd'},
	{"ftrace"   , required_argument, NULL, 'f'},
    {0          , 0                , NULL,  0 },
  };
  int o;
  while ( (o = getopt_long(argc, argv, "-l:d:f:", table, NULL)) != -1) {
    switch (o) {
      case 'l': log_file = optarg; break;
      case 1: img_file = optarg; return 0;
	  case 'f': elf_file = optarg; break;
	  case 'd': diff_so_file = optarg; break;
      default:
        printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
        printf("\t-l,--log=FILE           output log to FILE\n");
        printf("\n");
        exit(0);
    }
  }
  return 0;
}

void init_monitor(int argc, char *argv[]) {
	/* Perform some global initialization*/
	
	/*Parse arguments. */
	parse_args(argc, argv);

  	/* Initialize log*/
  	init_log(log_file);

	/* Initialize elf*/
	init_elf(elf_file);

	/* Initialize memory. */
	init_mem();

	/* Load the image to memory. This will overwrite the built-in image. */	
	long img_size = load_img();
	printf("Load image from %s with size = %x\n", img_file, img_size);

	/* Initialize disassemble module*/
#ifdef CONFIG_ITRACE
  	init_disasm("riscv32-pc-linux-gnu");
#endif
	/* Initialize the top module*/	
	CPU_State cpu = sim_init_then_reset(argc, argv);

#ifdef CONFIG_DIFFTEST
	init_difftest(diff_so_file, img_size, 1234);
#endif
}