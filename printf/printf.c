#include <stdio.h>
void call_printf(const char *format, ...);
void call_printf_from_c();

const char *prompt = "-What do u love?\n";

int main() {
   call_printf_from_c();
   printf("end of test\n");
   return 0;
}

void call_printf_from_c() { // call not from main to check correct ret to main (stack correctness)
    call_printf("-hehe %% %s %d %x %o %c he\n %d %d %s %x %d%%%c\n", "love", 0, -1, 1, 0x30, 
                                                              -1, -1, "sleep", 3802, 100, 33);
                                                              
    call_printf("%s%d %s %x %d%%%c%b\n", prompt, -1ll, "love", 3802, 100, 33, 127);
}