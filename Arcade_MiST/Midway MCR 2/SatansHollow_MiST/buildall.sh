#!/bin/sh

PROJECTS=" \
SHOLLOW \
TRON \
TWOTIGER \
WACKO \
KROOZR \
DOMINO"

for PROJECT in $PROJECTS; do
    echo "Compiling $PROJECT"
    sed -i "s/^.define CORE_NAME.*/\`define CORE_NAME \"$PROJECT\"/" rtl/SatansHollow_MiST.sv
    quartus_sh --flow compile SatansHollow.qsf && cp output_files/SatansHollow.rbf Releases/$PROJECT.rbf
done