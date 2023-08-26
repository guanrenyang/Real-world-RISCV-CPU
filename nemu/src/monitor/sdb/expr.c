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

/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include <regex.h>

enum {
  TK_NOTYPE = 256, TK_EQ,

  /* TODO: Add more token types */
  TK_POS_INT, TK_HEX_NUM,
  TK_REG,
};

static struct rule {
  const char *regex;
  int token_type;
} rules[] = {

  /* TODO: Add more rules.
   * Pay attention to the precedence level of different rules.
   */

  {" +", TK_NOTYPE},    // spaces
  /* Checking hex number must be done before checking decimal number, 
   * otherwise the leading 0 of 0x will be parsed sparately as `0`.*/
  {"0x[0-9a-fA-F]*", TK_HEX_NUM}, // hex number
  {"(^[1-9][0-9]*)|(^[0-9])", TK_POS_INT}, // positive integer
  {"\\$[\\$0-9a-z]*", TK_REG},
  {"\\+", '+'},         // plus
  {"\\-", '-'},         // minus
  {"\\*", '*'},         // multiply
  {"\\/", '/'},         // divide
  {"\\(", '('},         // left parenthesis
  {"\\)", ')'},         // right parenthesis
  {"==", TK_EQ},        // equal
};

#define NR_REGEX ARRLEN(rules)

static regex_t re[NR_REGEX] = {};

/* Rules are used for many times.
 * Therefore we compile them only once before any usage.
 */
void init_regex() {
  int i;
  char error_msg[128];
  int ret;

  for (i = 0; i < NR_REGEX; i ++) {
    ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
    if (ret != 0) {
      regerror(ret, &re[i], error_msg, 128);
      panic("regex compilation failed: %s\n%s", error_msg, rules[i].regex);
    }
  }
}

typedef struct token {
  int type;
  char str[32]; // The first 8 (sizeof(char *)) bytes is a pointer(char **) to the start of substr, the following 4 bytes (sizeof(int*)) is a pointer containing substr_len 
} Token;

static Token tokens[3200000] __attribute__((used)) = {};
static int nr_token __attribute__((used))  = 0;

static void store_metadata_to_token_str(char *token_str, char *substr_start, int substr_len){
  char **substr_start_pos = (char**) token_str;
  int *substr_len_pos = (int*)(substr_start_pos + 1);

  *substr_start_pos = substr_start;
  *substr_len_pos = substr_len;
}
static bool make_token(char *e) {
  int position = 0;
  int i;
  regmatch_t pmatch;

  nr_token = 0;

  while (e[position] != '\0') {
    /* Try all rules one by one. */
    for (i = 0; i < NR_REGEX; i ++) {
      if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0) {
        char *substr_start = e + position;
        int substr_len = pmatch.rm_eo;

        Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s", i, rules[i].regex, position, substr_len, substr_len, substr_start);


        /* TODO: Now a new token is recognized with rules[i]. Add codes
         * to record the token in the array `tokens'. For certain types
         * of tokens, some extra actions should be performed.
         */
        position += substr_len;

        switch (rules[i].token_type) {
          case '+': 
          case '-':
          case '*':
          case '/':
          case '(':
          case ')':
          case TK_POS_INT:
          case TK_HEX_NUM:
                tokens[nr_token].type = rules[i].token_type;
                store_metadata_to_token_str(tokens[nr_token].str, substr_start, substr_len);
                nr_token ++;
                break;
          case TK_REG:
                // isa_reg_str2val();
          case TK_NOTYPE:
                break;
          default: TODO();
        }
        
        // // For testing
        // char *test_substr = malloc(sizeof(char)*substr_len+1);
        // memset(test_substr, '\0', substr_len+1);
        // strncpy(test_substr, substr_start, substr_len);
        // printf("%s\n", test_substr); 
        // printf("%s\n", substr_start);
        // free(test_substr);
        break;
      }
    }

    if (i == NR_REGEX) {
      printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
      return false;
    }
  }

  return true;
}

bool check_parentheses(int p, int q){
  if(tokens[p].type!='(' || tokens[q].type!=')')  
    return false;
  
  // Next, check parenthesis matching
  p++;
  q--;
  if(p==q) //Single token
    return true;

  int nr_left_parenthesis = 0;
  int i;
  for (i=p;i<=q;i++){
    if (tokens[i].type=='(') {
      nr_left_parenthesis++;
    } else if (tokens[i].type==')'){
      if (nr_left_parenthesis==0) // No surrounding parenthesis 
        return false;
      nr_left_parenthesis--;
    }
  }
  
  if (nr_left_parenthesis!=0) {
    panic("Parenthesis not matching!");
  }

  return true;

}

word_t eval(int p, int q, bool *success){  
  if (p > q) { // First, check if it is a valid expression. 
    /* Bad expression */
    panic("Bad expression with p=%d, q=%d\n!", p, q);
  } else if (p == q) {
    /* Single token.
     * For now this token should be a number.
     * Return the value of the number.
     */
    Token token = tokens[p];
    if (token.type!=TK_POS_INT && token.type!=TK_HEX_NUM) {
      panic("Token should be a positive integer but it is not.");
    }
    
    char *substr_start = *((char **)token.str);
    int substr_len =  *( (int *)( (char **)token.str + 1 ) );
      
    char *substr;
    substr = malloc(substr_len * sizeof(char) + 1);
    memset(substr, '\0', substr_len * sizeof(char) + 1);

    strncpy(substr, substr_start, substr_len);
   
    word_t res;
    char *endptr;
    switch (token.type) {
      case TK_POS_INT:
        res = (word_t) strtoul(substr, &endptr, 10);
        if (endptr==substr) {
          panic("No digits were found!");
        }
        break;
      case TK_HEX_NUM:
        res = (word_t) strtoul(substr, &endptr, 16);
        if (endptr==substr) {
          panic("No digits were found!");
        }
        break;
      default: TODO();
    }
    
    
    free(substr);

    return res;

  } else if (check_parentheses(p, q) == true) {
    /* The expression is surrounded by a matched pair of parentheses.
     * If that is the case, just throw away the parentheses.
     */
    return eval(p + 1, q - 1, success);

  } else {

    int op=-1;
    // Find the main op
    int nr_left_parenthesis = 0;
    int i;
    for (i=p;i<=q;i++){
      int token_type = tokens[i].type;
      if (token_type=='(') {
        nr_left_parenthesis++;
      } else if (token_type==')') {
        nr_left_parenthesis--;
      } else if (nr_left_parenthesis==0) {
        if ( token_type=='+' || token_type=='-' ) {
          op = i;
        } else if (( token_type=='*' || token_type=='/' ) && (op==-1 || (tokens[op].type!='+' && tokens[op].type!='-'))) {
          op = i;  
        } 
      }
    }

    int val1 = eval(p, op - 1, success);
    int val2 = eval(op + 1, q, success);

    switch (tokens[op].type) {
      case '+': return val1 + val2;
      case '-': return val1 - val2;
      case '*': return val1 * val2; 
      case '/': 
        if (val2==0)
          *success = false;
        return val1 / val2; 
      default: assert(0);
    }
  }
  return 0;
}

word_t expr(char *e, bool *success) {
  if (!make_token(e)) {
    *success = false;
    return 0;
  }
  // Check if the parenthesis match correctly
  int nr_left_parenthesis = 0;
  int i;
  for (i=0;i<nr_token;i++){
    if (tokens[i].type=='(') {
      nr_left_parenthesis++;
    } else if (tokens[i].type==')'){
      if (nr_left_parenthesis==0) {// No surrounding parenthesis 
        panic("Invalid expression: Parenthesis not matching!\n");
        (*success) = false;
        return 0;
      }
      nr_left_parenthesis--;
    }
  }
  if ( nr_left_parenthesis!=0 ){
    panic("Invalid expression: Parenthesis not matching!\n");
    (*success) = false;
    return 0;
  }
    
  // Evaluate the expression
  (*success) = true;
  word_t res = eval(0, nr_token-1, success);

  return res;
}
