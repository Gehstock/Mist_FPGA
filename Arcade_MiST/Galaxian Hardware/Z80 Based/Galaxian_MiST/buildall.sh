#!/bin/sh

PROJECTS=" \
GALAXIAN \
MOONCR \
AZURIAN \
BLACKHOLE \
CATACOMB \
CHEWINGG \
DEVILFSH \
KINGBAL \
MRDONIGH \
OMEGA \
ORBITRON \
PISCES \
UNIWARS \
VICTORY \
WAROFBUG \
TRIPLEDR"

for PROJECT in $PROJECTS; do
    echo "Compiling $PROJECT"
    sed -i "s/^.define NAME.*/\`define NAME \"$PROJECT\"/" rtl/Galaxian_MiST.sv
    quartus_sh --flow compile Galaxian.qsf && cp output_files/Galaxian.rbf Releases/$PROJECT.rbf
done