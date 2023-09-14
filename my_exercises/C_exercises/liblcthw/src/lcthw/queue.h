#ifndef _queue_h
#define _queue_h

#include <lcthw/list.h>

#define Queue List

#define Queue_create List_create
#define Queue_destroy List_destroy

#define Queue_send List_push
#define Queue_recv List_shift

#define Queue_peek(A) (A)->first->value
#define Queue_count(A) (A)->count

#define QUEUE_FOREACH(L, V) LIST_FOREACH(L, first, next, V)
#endif // !_queue_h
