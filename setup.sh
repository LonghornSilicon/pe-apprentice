# Source this once per session, after you get onto a compute node.
#
#   % bash
#   % qsh -q normal.q -now n -V
#   % bash
#   % source ~/pe-apprentice/tools/setup.sh

if ! type module >/dev/null 2>&1; then
  [ -f "${MODULESHOME}/init/bash" ] && . "${MODULESHOME}/init/bash"
fi

module load genus/211/21.18.000
module load innovus/211/21.18.000
module load xcelium/2403/24.03.005
module load assura/41/618/04.17.001

# gsclib045 is the digital standard-cell library. GPDK045 on its own is analog
# only, which is why this path is so deep.

export GSCLIB=/process/hosted/gpdk/gpdk045/ip_libraries/gsclib045/v4p4/gsclib045

export LIB_SS=$GSCLIB/timing/slow_vdd1v0_basicCells.lib
export LIB_FF=$GSCLIB/timing/fast_vdd1v0_basicCells.lib
export LEF_TECH=$GSCLIB/lef/gsclib045_tech.lef
export LEF_MACRO=$GSCLIB/lef/gsclib045_macro.lef
export STDCELLS_V=$GSCLIB/verilog/slow_vdd1v0_basicCells.v
export STDCELLS_CDL=$GSCLIB/cdl/gsclib045.cdl
export STDCELLS_GDS=$GSCLIB/gds/gsclib045.gds
export STREAM_MAP=/process/hosted/gpdk/gpdk045/oa/v6p0/soce/streamOut.map
export ASSURA_RULES=/process/hosted/gpdk/gpdk045/oa/v6p0/assura

export PE_PYTHON=/grid/common/bin/python3

# Innovus assumes 90nm unless told. In Innovus, after init_design:
#   set_db design_process_node 45

echo "pe-apprentice environment loaded"
echo "  genus   $(command -v genus   || echo MISSING)"
echo "  innovus $(command -v innovus || echo MISSING)"
echo "  xrun    $(command -v xrun    || echo MISSING)"
echo "  assura  $(command -v assura  || echo MISSING)"
echo "  GSCLIB  $GSCLIB"
