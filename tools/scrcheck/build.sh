#!/usr/bin/env bash
# Builds a standalone .scr syntax checker from the engine's own lexer+grammar.
# Catches parse errors offline, without loading a map on the live server.
#
# SCOPE: grammar only. It runs the engine's yyparse() but stops before codegen,
# so duplicate labels, bad lvalues and illegal break/continue (ScriptCompiler::
# CompileError) still only surface at map load. "OK" == the parser accepts it.
#
# Normally you don't run this directly — `just scrcheck` builds on demand:
#   just scrcheck                             # every script under main/
#   just scrcheck main/global/feho/squad.scr  # specific files
#   just scrcheck-changed                     # only what you've edited
#   just scrcheck-rebuild                     # after pulling engine changes
#
# Requires the openmohaa checkout (for code/parser + code/corepp sources);
# override its location with OPENMOHAA_DIR.
set -euo pipefail
O="${OPENMOHAA_DIR:-$HOME/dev/openmohaa}"
[ -d "$O/code/parser" ] || { echo "openmohaa not found at $O; set OPENMOHAA_DIR" >&2; exit 1; }
here="$(cd "$(dirname "$0")" && pwd)"; obj="$here/.obj"; mkdir -p "$obj"
CXXFLAGS=(-O0 -fPIC -std=gnu++20 -w
  -DARCHIVE_SUPPORTED -DGAME_DLL -DNDEBUG -DWITH_SCRIPT_ENGINE -D_LINUX=1
  -I"$O/code/qcommon" -I"$O/code/script" -I"$O/code/parser"
  -I"$O/code/parser/generated" -I"$O/code/fgame" -I"$O/code/corepp"
  -I"$O/code/gamespy/common")
srcs=("$O/code/parser/generated/yyParser.cpp" "$O/code/parser/generated/yyLexer.cpp"
      "$O/code/parser/parsetree.cpp" "$O/code/corepp/str.cpp"
      "$O/code/corepp/mem_tempalloc.cpp" "$here/stubs.cpp" "$here/synchk.cpp")
objs=()
for f in "${srcs[@]}"; do
  o="$obj/$(basename "$f").o"; g++ "${CXXFLAGS[@]}" -c "$f" -o "$o"; objs+=("$o")
done
g++ -o "$here/scrcheck" "${objs[@]}"
echo "built $here/scrcheck"
