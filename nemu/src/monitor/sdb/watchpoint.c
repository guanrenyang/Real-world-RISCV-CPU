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

#include "sdb.h"

#define NR_WP 32

typedef struct watchpoint {
  int NO;
  struct watchpoint *next;

  /* TODO: Add more members if necessary */
  char *expr;
  word_t value;
} WP;

static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;

void init_wp_pool() {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
    wp_pool[i].expr = NULL;
  }

  head = NULL;
  free_ = wp_pool;
}

/* TODO: Implement the functionality of watchpoint */
void new_wp(char expr[]){
  if (free_ == NULL) {
    panic("No free watchpoint remains!\n");
  } 
 
  WP* new_free_wp = free_;
  free_ = free_ -> next;

  // set expr
  new_free_wp -> expr = malloc(sizeof(char) * strlen(expr) + 1);
  memset(new_free_wp -> expr, '\0', sizeof(char) * strlen(expr) + 1);
  strcpy(new_free_wp -> expr, expr);

  if (head==NULL) {
    new_free_wp -> NO = 0;
    new_free_wp -> next = NULL;
    head = new_free_wp;
  } else {
    new_free_wp -> NO = (head -> NO) + 1;
    new_free_wp -> next = head;
    head = new_free_wp;
  }

}

void free_wp(int NO){
  if (head == NULL) {
    panic("No watchpoint existing now!\n");
  }

  WP* candidate = head;
  WP* prev_candidate = NULL;

  while (candidate != NULL && candidate->NO != NO) {
    prev_candidate = candidate;
    candidate = candidate -> next;
  }

  if (candidate == NULL){
    panic("No watchpoint with NO=%d\n", NO);
  }
 
  // Remove candidate from in-use watchpoint list
  if (prev_candidate==NULL){
    head = NULL;
  } else {
    prev_candidate -> next = candidate -> next;
  }
 
  // Set candidate
  candidate -> NO = 0;
  free(candidate -> expr); 

  // Insert candidate into free watchpoint list
  if (free_ == NULL) {
    candidate -> next = NULL;
    free_ = candidate;
  } else {
    candidate -> next = free_;
    free_ = candidate;
  }
}









