#include <stdio.h>
void call_printf(const char *format, ...);
void call_printf_from_c();

int main() {
   call_printf_from_c();
   printf("end of test\n");
   return 0;
}

void call_printf_from_c() { // call not from main to check correct ret to main (stack correctness)
    call_printf("-hehe %% %s %d %x %o %c he\n %d %d %s %x %d%%%c%c\n", "love", 0, -1, 1, 0x30, 
                                                            -1ll, -1ll, "sleep", 3802, 100, 33, 33);
}