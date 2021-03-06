
%top{
#define UTILITY_NAME "hlsym"

#include "common.h"
}

%{
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>

#include "arg_parser.h"
#include "termcols.h"
#include "file.h"

static const char *arg_str = "[Flags] [Files]";
static const char *usage_str = "Apply syntax-highlighting to Files\n";
static const char *arg_desc_str  = "Files: List of files to output with syntax highlighting.\n";

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

void fake_func(void) {
    yyunput(0, NULL);
}

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

    while ((ret = arg_parser(argc, argv, args)) != ARG_DONE) {
        switch (ret) {
        case ARG_help:
            display_help_text(argv[0], arg_str, usage_str, arg_desc_str, args);
            break;
        case ARG_version:
            printf("%s", version_text);
            return 0;
        case ARG_EXTRA:
            had_files = true;
            file = fopen_with_dash(argarg, "r");
            if (file == NULL) {
              perror(argarg);
              return 1;
            }
            output_with_highlight(file);
            fclose_with_dash(file);
            break;
        default:
            return 0;
        }
    }

    if (!had_files) {
        output_with_highlight(stdin);
    }
}

