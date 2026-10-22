# Source this once per session, after you get onto a compute node.
#
#   % srun -c 4 --mem=16G --pty bash
#   $ source ~/pe-apprentice/setup.sh
#
# The login shell on SJ24 is csh. srun gives you a bash shell on a compute
# node; this file is written for that bash. Always pass -c and --mem: without
# --mem Slurm here allocates the whole node's memory to you.

if ! type module >/dev/null 2>&1; then
  : "${MODULESHOME:=/apps/modules-v3.2.6a-64bit/Modules}"
  [ -f "${MODULESHOME}/init/bash" ] && . "${MODULESHOME}/init/bash"
fi

# The license module sets CDS_LIC_FILE to 5280@sj24ut01. Load it first.
module load license

module load genus/211/21.17.000
# innovus/211/21.17.000 is on disk with an empty bin/ and no modulefile.
# 21.19.000 is the newest 211 leaf and is in the same database family as
# Genus 21.17. Verified 2026-10-21.
module load innovus/211/21.19.000
module load xcelium/2403/24.03.013
module load assura/41/618/04.16.111
# Tempus, for signoff timing. 211 to match Genus and Innovus.
module load ssv/211/21.15.000

# klayout, for looking at a GDS outside Innovus.
export PATH=/grid/common/pkgs/klayout/latest/bin:$PATH

# gsclib045 is the digital standard-cell library. GPDK045 on its own is analog
# only, which is why this path is so deep.
#
# NOT INSTALLED ON SJ24 YET. /process is empty. The path below is where it
# lived on the old chamber and where we have asked Cadence to put it. Until
# it exists, weeks 6, 7, 9 and 10 cannot run here; the check at the bottom
# prints MISSING.

export PDK_ROOT=/process/hosted/gpdk/gpdk045
export GSCLIB=$PDK_ROOT/ip_libraries/gsclib045/v4p4/gsclib045

export LIB_SS=$GSCLIB/timing/slow_vdd1v0_basicCells.lib
export LIB_FF=$GSCLIB/timing/fast_vdd1v0_basicCells.lib
export LEF_TECH=$GSCLIB/lef/gsclib045_tech.lef
export LEF_MACRO=$GSCLIB/lef/gsclib045_macro.lef
export STDCELLS_V=$GSCLIB/verilog/slow_vdd1v0_basicCells.v
export STDCELLS_CDL=$GSCLIB/cdl/gsclib045.cdl
export STDCELLS_GDS=$GSCLIB/gds/gsclib045.gds
export STREAM_MAP=$PDK_ROOT/oa/v6p0/soce/streamOut.map
export ASSURA_RULES=$PDK_ROOT/oa/v6p0/assura

# Pin layers for week 9: the lowest layer whose preferred DIRECTION is
# HORIZONTAL (west/east pins) and the lowest that is VERTICAL (north/south
# pins), read from $LEF_TECH. Metal3/Metal2 is the Cadence convention for this
# kit; confirm with  grep -A4 "^LAYER Metal3$" $LEF_TECH  before week 9.
export PIN_LAYER_H=Metal3
export PIN_LAYER_V=Metal2

# Python 3.6.8. f-strings work; dataclasses and walrus do not.
export PE_PYTHON=/bin/python3

# Your working space. Home directories are small and may be purged; the
# project volume is ours and is where run output belongs. SETUP.md puts the
# repo here and symlinks ~/pe-apprentice to it.
export PE_WORK=/projects/library/$USER
mkdir -p "$PE_WORK" 2>/dev/null
# 2750: you read and write, the roster (group librarysj24) reads, nobody
# else sees it. The leading 2 keeps new files in the group.
chmod 2750 "$PE_WORK" 2>/dev/null

# Innovus assumes 90nm unless told. In Innovus, after init_design:
#   set_db design_process_node 45

echo "pe-apprentice environment loaded on $(hostname)"
echo "  genus   $(command -v genus   || echo MISSING)"
echo "  innovus $(command -v innovus || echo MISSING)"
echo "  xrun    $(command -v xrun    || echo MISSING)"
echo "  assura  $(command -v assura  || echo MISSING)"
echo "  tempus  $(command -v tempus  || echo MISSING)"
echo "  klayout $(command -v klayout || echo MISSING)"
echo "  license ${CDS_LIC_FILE:-MISSING}"
if [ -f "$LIB_SS" ]; then echo "  GSCLIB  $GSCLIB"; else echo "  GSCLIB  MISSING (no PDK on SJ24 yet; tell a lead)"; fi
echo "  work    $PE_WORK"
