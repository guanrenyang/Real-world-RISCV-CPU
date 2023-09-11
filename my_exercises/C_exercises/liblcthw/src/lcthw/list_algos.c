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

List *List_merge_sort(List *list, List_compare cmp)
{
  return NULL;
}
