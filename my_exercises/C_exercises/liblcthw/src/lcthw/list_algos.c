#include <lcthw/list_algos.h>
#include <lcthw/dbg.h>

void ListNode_swap(ListNode *node1, ListNode *node2)
{
  check_mem(node1);
  check_mem(node2);

  void *tmp;
  tmp = node2->value;
  node2->value = node1->value;
  node1->value = tmp;
error:
  return ;
}

int List_bubble_sort(List *list, List_compare cmp)
{
  if (list == NULL || list->first==list->last)  
      return 0;
  
  int sorted = 1;
  while (sorted) {
    LIST_FOREACH(list, first, next, cur){
      if (cur->next && cmp(cur->value, cur->next->value)>0) {
        sorted = 0;
        ListNode_swap(cur, cur->next);
      }
    }
    if (sorted) {
      return 0;
    }

    sorted = 1;
  }
 
  return 0;
  
}

List *List_merge(List *list_1, List *list_2, List_compare cmp){
  List *result = List_create();
 
  void* value_1;
  void* value_2;
  while (list_1->count && list_2->count) {
    value_1 = list_1->first->value;
    value_2 = list_2->first->value;
    if (cmp(value_1, value_2)>0) {
      List_push(result, value_2);
      List_shift(list_2);
    } else {
      List_push(result, value_1);
      List_shift(list_1);
    }
  }
  void *value;
  while (list_1->count) {
    value = List_shift(list_1);
    List_push(result, value);
  }
  while (list_2->count) {
    value = List_shift(list_2);
    List_push(result, value);
  }
  
  return result;
}

List *List_merge_sort(List *list, List_compare cmp)
{
  check_mem(list);
  check(list->count!=0, "Error: merge an empty list.");

  if (list->count==1) {
    return list;
  }  
  
  List *left = List_create();
  List *right = List_create();

  int i=0;
  LIST_FOREACH(list, first, next, cur){
    if (i<(list->count)/2)
      List_push(left, cur->value);
    else 
      List_push(right, cur->value);
    i++;
  }

  left = List_merge_sort(left, cmp);
  right = List_merge_sort(right, cmp);
  List * result = List_merge(left, right, cmp);

  List_destroy(left);
  List_destroy(right);

error:
  return result;
}














