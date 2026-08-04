// Minimal stubs so the engine parser links without the game DLL.
// Only the parse path is exercised; error paths abort loudly rather than
// pretending to succeed.
#include "scriptcompiler.h"
#include "yyParser.hpp"
#include <cstdio>
#include <cstdlib>
#include <cstdarg>

ScriptCompiler Compiler;
gameImport_s   gi;
cvar_t        *g_showopcodes = nullptr;

void ScriptCompiler::CompileError(unsigned int sourcePos, const char *fmt, ...)
{
    va_list ap; va_start(ap, fmt);
    fprintf(stderr, "LEXERROR: "); vfprintf(stderr, fmt, ap); fprintf(stderr, "\n");
    va_end(ap);
    exit(1);
}

// Mirrors the real yyerror (scriptcompiler.cpp:1487) minus the
// gameScript->PrintSourcePos call, which needs game state we don't have.
extern int   prev_yylex;
extern int   yylineno;
extern char *yytext;

int yyerror(const char *msg)
{
    parsedata.exc.yylineno = prev_yylex != TOKEN_EOL ? yylineno : yylineno - 1;
    parsedata.exc.yytext   = yytext;
    parsedata.exc.yytoken  = msg;
    parsedata.pos++;
    return 1;
}

ScriptCompiler::ScriptCompiler() {}
