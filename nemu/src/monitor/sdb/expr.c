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
#include <memory/paddr.h>
/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include <regex.h>

enum {
  TK_NOTYPE = 256, TK_EQ, TK_NOEQ, TK_AND,

  /* TODO: Add more token types */
  TK_POS_INT, TK_HEX_NUM,
  TK_REG,
  
  TK_PTR_DEREF, 
  TK_NEGATE,
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
  {"\\$[\\$0-9a-z]*", TK_REG}, // register name
  {"\\+", '+'},         // plus
  {"\\-", '-'},         // minus
  {"\\*", '*'},         // multiply
  {"\\/", '/'},         // divide
  {"\\(", '('},         // left parenthesis
  {"\\)", ')'},         // right parenthesis
  {"==", TK_EQ},        // equal
  {"!=", TK_NOEQ},      // not equal
  {"&&", TK_AND},       // and
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

static void store_metadata_to_token_str(void *token_str, char *substr_start, int substr_len){
  char **substr_start_pos = (char**) token_str;
  int *substr_len_pos = (int*)(substr_start_pos + 1);

  *substr_start_pos = substr_start;
  *substr_len_pos = substr_len;
}

static word_t parse_number_from_token_str(void *token_str, int base){
  char *substr_start = *((char **)token_str);
  int substr_len =  *( (int *)( (char **)token_str + 1 ) );
  
  char *substr;
  substr = malloc(substr_len * sizeof(char) + 1);
  memset(substr, '\0', substr_len * sizeof(char) + 1);

  strncpy(substr, substr_start, substr_len);
  
  word_t res;
  char *endptr;
  res = (word_t) strtoul(substr, &endptr, base);
  if (endptr==substr) {
    panic("No digits were found!");
  }

  free(substr);
  return res;
}
static word_t parse_reg_val_from_token_str(void *token_str, bool *success){
  char *substr_start = *((char **)token_str);
  int substr_len =  *( (int *)( (char **)token_str + 1 ) );
 
  char *regname = malloc(substr_len * sizeof(char) + 1);
  memset(regname, '\0', substr_len * sizeof(char) + 1);
  
  strncpy(regname, substr_start+1, substr_len-1); // Omit the leading $ in register name

  word_t res = isa_reg_str2val(regname, success);

  free(regname);
  return res;
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
          case '/':
          case '(':
          case ')':
          case TK_POS_INT:
          case TK_HEX_NUM:
          case TK_REG:
          case TK_NOEQ:
          case TK_EQ:
          case TK_AND:
                tokens[nr_token].type = rules[i].token_type;
                store_metadata_to_token_str(tokens[nr_token].str, substr_start, substr_len);
                nr_token++;
                break;
          case '-':
                if (nr_token==0 || (tokens[nr_token-1].type!=TK_POS_INT && tokens[nr_token-1].type!=TK_HEX_NUM && tokens[nr_token-1].type!=TK_REG && tokens[nr_token-1].type!=')'))
                  tokens[nr_token].type = TK_NEGATE;
                else
                  tokens[nr_token].type = '-';
                store_metadata_to_token_str(tokens[nr_token].str, substr_start, substr_len);
                nr_token++;
                break;
          case '*': 
                if (nr_token==0 || (tokens[nr_token-1].type!=TK_POS_INT && tokens[nr_token-1].type!=TK_HEX_NUM && tokens[nr_token-1].type!=TK_REG && tokens[nr_token-1].type!=')'))
                  tokens[nr_token].type = TK_PTR_DEREF;
                else
                  tokens[nr_token].type = '*';
                store_metadata_to_token_str(tokens[nr_token].str, substr_start, substr_len);
                nr_token++;
                break;
          case TK_NOTYPE:
                break;
          default: panic("You should not be here!\n");
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
    if (token.type!=TK_POS_INT && token.type!=TK_HEX_NUM && token.type!=TK_REG) {
      panic("Token should be a positive integer or register name but it is not.");
    }

    word_t res = 0;
    switch (token.type) {
      case TK_POS_INT:
        res = parse_number_from_token_str(token.str, 10);
        break;
      case TK_HEX_NUM:
        res = parse_number_from_token_str(token.str, 16);
        break;
      case TK_REG:
        res = parse_reg_val_from_token_str(token.str, success);
        break;
      default: panic("You should not be here!");
    }
    
    return res;

  } else if (p == q - 1) {
    assert(tokens[p].type==TK_NEGATE || tokens[p].type==TK_PTR_DEREF); 
  
    word_t operand;
    switch (tokens[q].type) {
      case TK_HEX_NUM: operand = parse_number_from_token_str(tokens[q].str, 16); break;
      case TK_POS_INT: operand = parse_number_from_token_str(tokens[q].str, 10); break;
      case TK_REG: operand = parse_reg_val_from_token_str(tokens[q].str, success); break;
      default: panic("You should not be here!");
    }

    switch (tokens[p].type) {
      case TK_NEGATE: return -operand;
      case TK_PTR_DEREF: return paddr_read((paddr_t)operand, 4);
    }

  } else if (check_parentheses(p, q) == true) {
    /* The expression is surrounded by a matched pair of parentheses.
     * If that is the case, just throw away the parentheses.
     */
    return eval(p + 1, q - 1, success);

  } else {

    // Find the main op
    int op=-1;
    int nr_left_parenthesis = 0;
    int i;
    for (i=p;i<=q;i++){
      int token_type = tokens[i].type;
      switch (token_type) {
        case '(': nr_left_parenthesis++; break;
        case ')': nr_left_parenthesis--; break;
        case TK_AND: 
          if (nr_left_parenthesis!=0) break; 
          op = i; break;
        case TK_EQ:
        case TK_NOEQ:
          if (nr_left_parenthesis!=0) break;
          if (op!=-1 && tokens[op].type==TK_AND)  break;
          op = i; break;
        case '+':
        case '-':
          if (nr_left_parenthesis!=0) break;
          if (op!=-1 && (tokens[op].type==TK_AND || tokens[op].type==TK_EQ || tokens[op].type==TK_NOEQ)) break;
          op = i; break;
        case '*':
        case '/':
          if (nr_left_parenthesis!=0) break;
          if (op!=-1 && (tokens[op].type==TK_AND || tokens[op].type==TK_EQ || tokens[op].type==TK_NOEQ || tokens[op].type=='+' || tokens[op].type=='-')) break;
          op = i; break;
      }
    }
   
    if (op==-1) { // no main op, meaning that it is a series of single operand operator
      assert(tokens[p].type==TK_NEGATE || tokens[p].type==TK_PTR_DEREF); 
  
      switch (tokens[p].type) {
        case TK_NEGATE: return -eval(p+1, q, success);
        case TK_PTR_DEREF: return paddr_read(eval(p+1, q, success), 4);
      }
    } else {
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
        case TK_EQ: return val1 == val2;
        case TK_NOEQ: return val1 != val2;
        case TK_AND: return val1 && val2;
        default: assert(0);
      }        
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
