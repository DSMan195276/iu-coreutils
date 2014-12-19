// lnum - prepend line numbers to the given input (stdin by default)
//      - intended to be used as a filter.

#include <stdio.h>

#define MAX_LINE_SIZE 1000

void show_line_numbers(FILE *in);

int main(int argc, char **argv) {

  if (argc == 1) {
    show_line_numbers(stdin);
  } else {
    FILE *read = fopen( argv[1], "r" );
    if (read == NULL) { printf( "*** lnum: %s cannot be opened\n", argv[1] ); }
    else { show_line_numbers(read); }
  }

}

void show_line_numbers(FILE *in) {
  int line_count = 1;
  char line[MAX_LINE_SIZE];

  while ( fgets(line, MAX_LINE_SIZE, in) ) {
    printf("%d\t%s", line_count, line);
    line_count++;
  }
}
