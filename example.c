// example - Boiler-plate code for most utilities

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "arg_parser.h"

static const char *usage_str = "";
static const char *desc_str  = "";

#define XARGS \
    X(last, NULL, '\0', 0, NULL, NULL)

enum arg_index {
  ARG_EXTRA = ARG_PARSER_EXTRA,
  ARG_ERR = ARG_PARSER_ERR,
  ARG_DONE = ARG_PARSER_DONE,
#define X(enu, ...) ARG_ENUM(enu)
  XARGS
#undef X
};

static const struct arg test_args[] = {
#define X(...) CREATE_ARG(__VA_ARGS__)
  XARGS
#undef X
};

int main(int argc, char **argv) {
    enum arg_index ret;

    while ((ret = arg_parser(argc, argv, test_args)) != ARG_DONE) {
        switch (ret) {

        case ARG_EXTRA:

        case ARG_ERR:
        default:
            return 0;
        }
    }

    return 0;
}

