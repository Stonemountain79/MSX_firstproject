#!/usr/bin/env sh
set -e

ASM="sjasmplus"
if [ -x "../../../../assembler/sjasmplus" ]; then
    ASM="../../../../assembler/sjasmplus"
elif [ -x "../../../assembler/sjasmplus" ]; then
    ASM="../../../assembler/sjasmplus"
fi

rm -f game.rom
printf '%s\n' "$ASM game.asm --raw=game.rom"
"$ASM" game.asm --raw=game.rom

if [ ! -f game.rom ]; then
    echo "ERROR: game.rom was not created." >&2
    echo "Use manually: sjasmplus game.asm --raw=game.rom" >&2
    exit 1
fi

SIZE=$(wc -c < game.rom | tr -d ' ')
echo "ROM created: $(pwd)/game.rom"
echo "Size: $SIZE bytes"

if [ "$SIZE" != "16384" ]; then
    echo "WARNING: expected 16384 bytes for a 16 KB ROM." >&2
    exit 1
fi
