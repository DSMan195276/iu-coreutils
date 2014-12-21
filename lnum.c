// lnum - prepend line numbers to the given input (stdin by default)
//      - intended to be used as a filter.

#include <stdio.h>
#include <stdbool.h>
#include <string.h>

#include "arg_parser.h"

#define MAX_LINE_SIZE 1000

static const char *usage_str = "[Flags] [Files]";
static const char *desc_str  = "Files: List of files to output with line-numbers added.\n";

#define XARGS \
    X(help, "help", 0, 'h', "Display help") \
    X(last, NULL, 0, '\0', NULL)

enum arg_index {
  ARG_EXTRA = ARG_PARSER_EXTRA,
  ARG_LNG = ARG_PARSER_LNG,
  ARG_ERR = ARG_PARSER_ERR,
  ARG_DONE = ARG_PARSER_DONE,
#define X(enu, id, arg, op, help_text) ARG_##enu,
  XARGS
#undef X
};

static const struct arg lnum_args[] = {
#define X(enu, id, arg, op, help_text) [ARG_##enu] = { .lng = id, .shrt = op, .help_txt = help_text, .has_arg = arg },
  XARGS
#undef X
};


void show_line_numbers(FILE *in);

int main(int argc, char **argv) {
  bool had_files = false;
  FILE *file;
  enum arg_index ret;

  while ((ret = arg_parser(argc, argv, lnum_args)) != ARG_DONE) {
    switch (ret) {
    case ARG_help:
      display_help_text(argv[0], usage_str, desc_str, lnum_args);
      return 0;
    case ARG_EXTRA:
      had_files = true;
      if (strcmp(argarg, "-") != 0) {
        file = fopen(argarg, "r");
        if (file == NULL) {
          perror(argarg);
          return 1;
        }
        show_line_numbers(file);
        fclose(file);
      } else {
        show_line_numbers(stdin);
      }
      break;
    default:
      return 0;
    }
  }

  if (!had_files) {
    show_line_numbers(stdin);
  }
}

void show_line_numbers(FILE *in) {
  static int line_count = 1; /* Static, so the lines continue over multiple files */
  char line[MAX_LINE_SIZE];

  while ( fgets(line, MAX_LINE_SIZE, in) ) {
    printf("%d\t%s", line_count, line);
    line_count++;
  }
}

