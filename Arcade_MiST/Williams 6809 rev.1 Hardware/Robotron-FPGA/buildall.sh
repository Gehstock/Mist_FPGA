#!/bin/sh

PROJECTS=" \
ROBOTRON \
JOUST \
SPLAT \
BUBBLES \
STARGATE \
SINISTAR"

mkdir -p Releases
for PROJECT in $PROJECTS; do
    echo "Compiling $PROJECT"
    sed -i "s/^.define CORE_NAME.*/\`define CORE_NAME \"$PROJECT\"/" rtl/RobotronFPGA_MiST.sv
    quartus_sh --flow compile RobotronFPGA.qsf && cp output_files/RobotronFPGA.rbf Releases/$PROJECT.rbf
done