/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>
#include <cpu/cpu.h>
#include <memory/paddr.h>
#include <readline/readline.h>
#include <readline/history.h>
#include "sdb.h"

static int is_batch_mode = false;

void init_regex();
void init_wp_pool();

/* We use the `readline' library to provide more flexibility to read from stdin. */
static char* rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(nemu) ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}

static int cmd_c(char *args) {
  cpu_exec(-1);
  return 0;
}


static int cmd_q(char *args) {
  nemu_state.state = NEMU_QUIT;
  return -1;
}

static int cmd_si(char *args) {
  int nr_instructions;
  if (args==NULL)
    nr_instructions = 1;
  else
    nr_instructions = atoi(args);
  
  cpu_exec(nr_instructions);
  return 0;
}

static int cmd_info(char *args){
  if (args==NULL || !strcmp(args, "r"))
    isa_reg_display();
  if (args==NULL || !strcmp(args, "w"))
    scan_watchpoint(true, NULL);
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
    
    /* compute expression */
    bool expr_success = false; 
    word_t expr_result = expr(arg_1, &expr_success);
    if (!expr_success)
        panic("Expression computation failed!");
    printf("%u\n", expr_result); 
    int nr_elem = atoi(arg_0);
    
    // char *addr_end;
    // paddr_t addr = strtoul(expr_result, &addr_end, 16);
    // if (addr_end==expr_result)
    //   panic("Long long conversion failed");

    paddr_t addr = (paddr_t) expr_result;

    int i;
    for (i=0;i<nr_elem;i++, addr+=4) {
      word_t elem = paddr_read(addr, 4); // read 4 bytes from addr
      printf("dec: %u, hex: %x\n", elem, elem);
    }
    return 0;
}

static int cmd_p(char *args){
  bool success;
  word_t res = expr(args, &success);
  
  if (success == true)
    printf("%u\n", res);
  else
    printf("Divide by zero!\n");

  return 0;
}

static int cmd_w(char *args){
  new_wp(args);
  return 0;
}

static int cmd_d(char *args){
  int NO = atoi(args);
  free_wp(NO);
  return 0;
}

static int cmd_test(char *args){
  FILE *fp = fopen("./tools/gen-expr/input", "r");
  if (!fp) {
    panic("Unable to load file!");
  }

  word_t correct_res;

  char line[1000000]; // Assuming a line doesn't exceed 256 characters.
  char str[1000000];  // Assuming a string doesn't exceed 250 characters.

  int id = 0;
  while (fgets(line, sizeof(line), fp)) {
    // sscanf scans the input string for formatted data. 
    // Here, it looks for an unsigned int and then a string. 
    // The %[^\n] format reads the rest of the line as a string.
    if (sscanf(line, "%u %[^\n]", &correct_res, str) == 2) {
        // printf("Read correct_res: %u\n", correct_res);
        // printf("Read string: %s\n", str);
        bool success;
        word_t res =  expr(str, &success);
        bool match = res==correct_res;
        if (match)
          printf("test_id: %d, match\n", id);
        else
          panic("test_id: %d, not match!", id);
        id++;
    }
  }
  return 0;
}
static int cmd_help(char *args);

static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  { "test", "Test command used when debugging.", cmd_test},
  { "help", "Display information about all supported commands", cmd_help },
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NEMU", cmd_q },

  /* TODO: Add more commands */
  { "si", "Step Instruction", cmd_si},
  { "info", "Information", cmd_info}, 
  { "x", "Scan Memory", cmd_x},
  { "p", "Print", cmd_p},
  { "w", "Set watchpoint", cmd_w}, 
  { "d", "Delete watchpoint", cmd_d},
};


#define NR_CMD ARRLEN(cmd_table)

static int cmd_help(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i ++) {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  }
  else {
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(arg, cmd_table[i].name) == 0) {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
}

void sdb_set_batch_mode() {
  is_batch_mode = true;
}

void sdb_mainloop() {
  if (is_batch_mode) {
    cmd_c(NULL);
    return;
  }

  for (char *str; (str = rl_gets()) != NULL; ) {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL) { continue; }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end) {
      args = NULL;
    }

#ifdef CONFIG_DEVICE
    extern void sdl_clear_event_queue();
    sdl_clear_event_queue();
#endif

    int i;
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(cmd, cmd_table[i].name) == 0) {
        if (cmd_table[i].handler(args) < 0) { return; }
        break;
      }
    }

    if (i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
  }
}

void init_sdb() {
  /* Compile the regular expressions. */
  init_regex();

  /* Initialize the watchpoint pool. */
  init_wp_pool();
}
