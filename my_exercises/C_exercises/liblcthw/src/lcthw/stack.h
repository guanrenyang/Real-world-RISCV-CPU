#pragma once

#include <lcthw/list.h>

#define Stack List

#define Stack_create List_create
#define Stack_destroy List_destroy

#define Stack_push List_push
#define Stack_pop List_pop

#define Stack_peek(A) (A)->last->value 
#define Stack_count(A) (A)->count 

#define STACK_FOREACH(L, V) LIST_FOREACH(L, last, prev, V)

