#include <stdlib.h>

void seedInit(void){
	srand(5);
}

int getRandNum (void) { 
	return rand()%31 + 1;
}
