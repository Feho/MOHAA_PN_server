// Standalone .scr syntax checker: drives the engine's real lexer+grammar
// (yyparse) without needing game state. Mirrors ScriptCompiler::Parse setup.
#include "scriptcompiler.h"
#include "parsetree.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>

extern int    yyparse(void);
extern void   yy_init_script(void);
extern int    yylex_destroy(void);
extern char  *start_ptr;
extern const char *in_ptr;
extern int    prev_yylex;
extern int    parseStage;

// Parse one file. Returns true if it FAILED.
static bool check_one(const char *path, bool quiet) {
    FILE *f = fopen(path, "rb");
    if (!f) { perror(path); return true; }
    fseek(f, 0, SEEK_END); long n = ftell(f); fseek(f, 0, SEEK_SET);
    char *buf = (char*)calloc(1, n + 2);
    if (!buf || (n > 0 && fread(buf, 1, n, f) != (size_t)n)) {
        fprintf(stderr, "FAIL %s: read error\n", path);
        fclose(f); free(buf); return true;
    }
    fclose(f);

    // Mirrors ScriptCompiler::Parse setup (scriptcompiler.cpp:1504).
    parsedata = yyparsedata();
    parsedata.sourceBuffer = buf;
    parsedata.gameScript   = nullptr;
    parsedata.braces_count = 0;
    start_ptr  = buf;
    prev_yylex = 0;
    parseStage = 0;      // PS_TYPE
    in_ptr     = "level";

    yy_init_script();
    parsetree_init();

    int  rc  = yyparse();
    bool bad = (rc != 0) || (parsedata.exc.yytoken != "");
    if (bad) {
        printf("FAIL %s: line %d: %s (near '%s')\n", path,
               parsedata.exc.yylineno, parsedata.exc.yytoken.c_str(),
               parsedata.exc.yytext ? parsedata.exc.yytext : "?");
    } else if (!quiet) {
        printf("OK   %s\n", path);
    }
    yylex_destroy();
    free(buf);
    return bad;
}

int main(int argc, char **argv) {
    // The temp allocator calls gi.Malloc/gi.Free; without these it jumps
    // through a null pointer on the first token.
    gi.Malloc = ::malloc;
    gi.Free   = ::free;
    gi.Printf = (void(*)(const char*,...))::printf;
    gi.DPrintf= (void(*)(const char*,...))::printf;

    bool quiet = false;
    int  first = 1;
    if (argc > 1 && strcmp(argv[1], "-q") == 0) { quiet = true; first = 2; }

    if (argc <= first) {
        fprintf(stderr, "usage: scrcheck [-q] <file.scr> [file.scr ...]\n"
                        "  -q  print only failures\n");
        return 2;
    }

    int failed = 0;
    for (int i = first; i < argc; i++) {
        if (check_one(argv[i], quiet)) failed++;
    }
    return failed ? 1 : 0;
}
