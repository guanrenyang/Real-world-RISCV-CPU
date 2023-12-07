#include <stdio.h>
#include <stdlib.h>
#include <readline/readline.h>
#include <readline/history.h>
#include <npc.h>
#include <paddr.h>

static char* rl_gets() {
	static char *line_read = NULL;

	if (line_read) {
		free(line_read);
		line_read = NULL;
	}
	
	line_read = readline("(sdb) ");
	
	if (line_read && *line_read) {
		add_history(line_read);
	}

	return line_read;
}

static int cmd_c(char *args) {
	npc_exec(-1);		
	return -1;
}

static int cmd_si(char *args) {
  int nr_instructions;
  if (args==NULL)
    nr_instructions = 1;
  else
    nr_instructions = atoi(args);
  
  npc_exec(nr_instructions);
  return 0;
}

static int cmd_info(char *args){
  if (args==NULL || !strcmp(args, "r"))
    reg_display();
  // if (args==NULL || !strcmp(args, "w"))
  //   scan_watchpoint(true, NULL);
  return 0;
}

static int cmd_x(char *args){
    char *args_end = args + strlen(args);

    /* extract the first token as the command */
    char *arg_0 = strtok(args, " ");
    if (arg_0 == NULL) {
      printf("Error occurs\n");
    } 
    
    char *arg_1 = arg_0 + strlen(arg_0) + 1;
    if (arg_1 >= args_end) {
      arg_1 = NULL;
    }
    
    int nr_elem = atoi(arg_0);
	uint32_t addr = strtoul(arg_1, NULL, 16);

    int i;
    for (i=0;i<nr_elem;i++, addr+=4) {
      uint32_t elem = paddr_read(addr, 4); // read 4 bytes from addr
      printf("dec: %u, hex: %x\n", elem, elem);
    }
    return 0;
}

static int cmd_q(char *args){
	sim_exit();
	exit(0);
	return -1;
}
static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  // { "test", "Test command used when debugging.", cmd_test},
  // { "help", "Display information about all supported commands", cmd_help },
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NPC", cmd_q },
  //
  // /* TODO: Add more commands */
  { "si", "Step Instruction", cmd_si},
  { "info", "Information", cmd_info}, 
  { "x", "Scan Memory", cmd_x},
  // { "p", "Print", cmd_p},
  // { "w", "Set watchpoint", cmd_w}, 
  // { "d", "Delete watchpoint", cmd_d},
};

#define ARRLEN(arr) (sizeof(arr) / sizeof(arr[0]))
#define NR_CMD ARRLEN(cmd_table)

void sdb_mainloop() {
	for (char *str; (str = rl_gets()) != NULL; ) {
		char *str_end = str + strlen(str);

		/* extract the first token as the command*/	
		char *cmd = strtok(str, " ");
		if (cmd == NULL) { continue; }

		/* treat the remaining string as the arguments,
		 * which may need further parsing
		 */
		char *args = cmd + strlen(cmd) + 1;
		if (args >= str_end) { args = NULL; }
		
		int i;
		for (i = 0; i < NR_CMD; i++) {
			if (strcmp(cmd, cmd_table[i].name) == 0) {
				if (cmd_table[i].handler(args) < 0) { return; }
				break;
			}
		}

		if (i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
	}
}