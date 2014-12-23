
%top{
#define _XOPEN_SOURCE
}

%{
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>

#include "arg_parser.h"
#include "termcols.h"

static const char *usage_str = "[Flags] [Files]";
static const char *desc_str  = "Files: List of files to output with syntax highlighting.\n";

#define XARGS \
    X(help, "help", 'h', 0, NULL, "Display help") \
    X(last, NULL, '\0', 0, NULL, NULL)

enum arg_index {
  ARG_EXTRA = ARG_PARSER_EXTRA,
  ARG_ERR = ARG_PARSER_ERR,
  ARG_DONE = ARG_PARSER_DONE,
#define X(enu, ...) ARG_ENUM(enu)
  XARGS
#undef X
};

static const struct arg hisyn_args[] = {
#define X(...) CREATE_ARG(__VA_ARGS__)
  XARGS
#undef X
};

#define YY_NO_INPUT

#define YY_DECL int yylex (void)

static int match_color = 0;

static char *match_colors[] = {
    TERM_COLOR_RED,
    TERM_COLOR_BLUE,
    TERM_COLOR_YELLOW,
    TERM_COLOR_MAGENTA
};

#define NUM_COLORS (sizeof(match_colors) / sizeof(*match_colors))
%}

%option noyywrap
%option case-insensitive

%x quotes
%x multi_line_comment
%x single_line_comment

%%

(";"|":") { printf(TERM_COLOR_RESET "%s", yytext); }

"," { printf("%s,", match_colors[(match_color - 1) % NUM_COLORS]); }

("{"|"("|"[") {
    printf("%s%s", match_colors[match_color % NUM_COLORS], yytext);
    match_color++;
}

("}"|")"|"]") {
    match_color--;
    printf("%s%s", match_colors[match_color % NUM_COLORS], yytext);
}

#(include|define|undef|if|elif|ifdef|ifndef|endif) {
    printf(TERM_COLOR_BLUE "%s", yytext);
}

(auto|const|extern|static|sizeof) {
    printf(TERM_COLOR_GREEN "%s", yytext);
}

(int|char|long|short|float|double|void|unsigned|signed|volatile|register) {
    printf(TERM_COLOR_MAGENTA "%s", yytext);
}

(break|switch|while|for|goto|if|return|continue|default|do|else|case) {
    printf(TERM_COLOR_YELLOW "%s", yytext);
}

(enum|struct|typedef|union) {
    printf(TERM_COLOR_BLUE "%s", yytext);
}

(0x[0-9a-fA-F]+|-?[0-9]+) {
    printf(TERM_COLOR_RED "%s", yytext);
}

'(.|\\x[0-9][0-9]|\\0[0-9]*)' {
    printf(TERM_COLOR_BLUE "%s", yytext);
}

"\"" {
    printf(TERM_COLOR_GREEN "\"");
    BEGIN(quotes);
}

<quotes>"\"" {
    printf("\"" TERM_COLOR_RESET);
    BEGIN(INITIAL);
}
<quotes>[^\"]+ {
    printf("%s", yytext);
}

"//" {
    printf(TERM_COLOR_BLUE "//");
    BEGIN(single_line_comment);
}

<single_line_comment>"\n" {
    printf(TERM_COLOR_RESET "\n");
    BEGIN(INITIAL);
}

<single_line_comment>[^\n]+ {
    printf("%s", yytext);
}

\n {
    printf(TERM_COLOR_RESET "\n");
}

[ \t]+ {
    printf(TERM_COLOR_RESET "%s", yytext);
}

[a-zA-Z1-9_.]+ {
    printf(TERM_COLOR_RESET "%s", yytext);
}

<<EOF>> {
    printf(TERM_COLOR_RESET);
    return 1;
}

%%

void output_with_highlight(FILE *in) {
    yyin = in;

    while (yylex() == 0)
        ;

    yylex_destroy();
    yyin = NULL;
}

int main(int argc, char **argv) {
    bool had_files = false;
    FILE *file;
    enum arg_index ret;

    while ((ret = arg_parser(argc, argv, hisyn_args)) != ARG_DONE) {
        switch (ret) {
        case ARG_help:
            display_help_text(argv[0], usage_str, desc_str, hisyn_args);
            break;
        case ARG_EXTRA:
            had_files = true;
            if (strcmp(argarg, "-") != 0) {
              file = fopen(argarg, "r");
              if (file == NULL) {
                perror(argarg);
                return 1;
              }
              output_with_highlight(file);
              fclose(file);
            } else {
              output_with_highlight(stdin);
            }
            break;
        default:
            return 0;
        }
    }

    if (!had_files) {
        output_with_highlight(stdin);
    }
}

