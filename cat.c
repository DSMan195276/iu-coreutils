// cat - read and output files
#define UTILITY_NAME "cat"

#include "common.h"

#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/select.h>

#include "arg_parser.h"

static const char *usage_str = "";
static const char *desc_str  = "";

#define XARGS \
    X(help, "help", 'h', 0, NULL, "Display help") \
    X(version, "version", 'v', 0, NULL, "Display version information") \
    X(last, NULL, '\0', 0, NULL, NULL)

enum arg_index {
  ARG_EXTRA = ARG_PARSER_EXTRA,
  ARG_ERR = ARG_PARSER_ERR,
  ARG_DONE = ARG_PARSER_DONE,
#define X(enu, ...) ARG_ENUM(enu)
  XARGS
#undef X
};

static const struct arg args[] = {
#define X(...) CREATE_ARG(__VA_ARGS__)
  XARGS
#undef X
};

void output_file(int in, const char *filename, int out);

int main(int argc, char **argv) {
    bool has_file = false;
    int file;
    enum arg_index ret;

    while ((ret = arg_parser(argc, argv, args)) != ARG_DONE) {
        switch (ret) {
        case ARG_help:
            display_help_text(argv[0], usage_str, desc_str, args);
            break;
        case ARG_version:
            printf("%s", version_text);
            return 0;

        case ARG_EXTRA:
            has_file = true;
            if (strcmp(argarg, "-") != 0) {
                file = open(argarg, O_RDONLY | O_NONBLOCK);
                if (file == -1) {
                    perror(argarg);
                    return 1;
                }
                output_file(file, argarg, STDOUT_FILENO);
                close(file);
            } else {
                output_file(STDIN_FILENO, "stdin", STDOUT_FILENO);
            }
            break;

        case ARG_ERR:
        default:
            return 0;
        }
    }

    if (!has_file)
        output_file(STDIN_FILENO, "stdin", STDOUT_FILENO);

    return 0;
}

#define BUFFER_SZ 1024

void output_file(int in, const char *filename, int out) {
  static char buffer[BUFFER_SZ];
  size_t sz;
  fd_set rdfds;

  do {
      int sel;
      FD_ZERO(&rdfds);
      FD_SET(in, &rdfds);

      sel = select(in + 1, &rdfds, NULL, NULL, NULL);

      if (sel == -1) {
          perror(filename);
          return ;
      }

      sz = read(in, buffer, sizeof(buffer));
      if (sz == 0)
          break;

      write(out, buffer, sz);
  } while (1);
}

