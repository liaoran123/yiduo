#include <stdio.h>
int main() {
    FILE* f = fopen("_build/yq_input.txt", "rb");
    if (f) {
        printf("OK\n");
        fclose(f);
        return 0;
    } else {
        printf("FAIL\n");
        return 1;
    }
}