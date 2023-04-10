#include <stdio.h>
#include <stdlib.h>
#include <SFML/Graphics.hpp>

//#include "Game.h"
#include "file_reading.h"

const int Hash_sum = 365360;
const int max_hash = 1000000;

int main(int argc, const char **argv) {
    CLArgs args = parse_cmd_line(argc, argv);
    size_t prog_size = count_elements_in_file(args.input);
    char *code = (char*) calloc(prog_size, sizeof(char));
    prog_size = read_file(code, prog_size, args.input);

    int hash = 0;
    for (size_t i = 0; i < prog_size; i++) {
        hash = (hash * 10 + code[i]) % max_hash;
    }

    if (hash != Hash_sum) {
        printf("%d Error: Yan's file for crack expected\n", hash);
        return 0;
    }

	//run_game();

    code[0] = 0xEB;
    code[1] = 0x50;

    write_to_file(code, prog_size, args.output);
    free(code);

    return 0;
}