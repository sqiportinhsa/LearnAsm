#include <stdio.h>

int main() {
    unsigned short hash = 0;
    for (int a = 32; a < 125; a++) {
        for (int b = 32; b < 125; b++) {
            for (int c = 32; c < 125; c++) {
                for (int d = 32; d < 125; d++) {
                    hash = 11*(11*(11*(11*a + b) + c) + d) + 13;
                    if (hash == 30322) {
                        printf("%d %d %d %d\n", a, b, c, d);
                    }
                }
            }
        }
    }
    printf("done\n");
    return 0;
}