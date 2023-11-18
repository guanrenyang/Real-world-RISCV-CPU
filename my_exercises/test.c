#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
int main(){
	int wmask = 0x0A;
	int bitMask = ((wmask & 1) * 0xFF) | ((((wmask & 2) >> 1)* 0xFF) << 8) | ((((wmask & 4) >> 2 ) * 0xFF) << 16) | ((((wmask & 8) >> 3 ) * 0xFF) << 24);
	printf("%x\n", bitMask);
	return 0;
}
 