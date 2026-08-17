#!/usr/bin/env bash
# ============================================================================
# pe-env.sh, chamber environment for the Longhorn Silicon apprentice program.
# ----------------------------------------------------------------------------
# Sourced by every run script and by chamber-diagnose. Never run directly.
#
# Descended from the Lambda chamber framework (lambda/tools/lib/lambda-env.sh),
# slimmed to what the apprentice flow needs. Every module pin and PDK path
# below was verified live on compute node ip-10-2-6-219 on 2026-08-16, see
# docs/00-chamber-and-repo-setup.md "Verified chamber state".
#
# Per-user overrides go in ~/.longhorn/pe.env (gitignored). It is sourced
# FIRST, then the committed defaults fill whatever is still unset, so an
# override of PE_WORK propagates into the paths derived from it.
# ============================================================================

# ---- Per-user overrides (sourced FIRST, see precedence note above) --------
if [[ -f "$HOME/.longhorn/pe.env" ]]; then
    # shellcheck disable=SC1091
    source "$HOME/.longhorn/pe.env"
fi

# ---- Paths ----------------------------------------------------------------
#   PE_ROOT  your clone of this repo. Source only. Tools never write here.
#   PE_WORK  the run area. Everything the tools emit lands here, OUTSIDE the
#            repo, so a `git checkout` or a fresh bundle can never destroy a
#            run and a run can never dirty your git status.
: "${PE_ROOT:=$HOME/longhorn-apprentice/pe-apprentice}"
: "${PE_WORK:=$HOME/work/pe}"
: "${PE_LOGS:=$PE_WORK/logs}"
: "${PE_FAST:=/tmp/${USER}-pe}"

# ---- Cadence module pins --------------------------------------------------
# Three-level leaves, not two-level. Two-level (e.g. `genus/211`) is legal;
# Environment Modules resolves to a default leaf. Pinning the leaf buys
# (a) reproducibility against silent default drift between nodes and weeks,
# and (b) a MATCHED RELEASE FAMILY across Genus and Innovus, which share
# database format within a family. The newest Genus on this chamber is
# 21.18.000, so Innovus is pinned to 21.18.000 too rather than the catalog
# default innovus/251 (= 25.14), which would force a cross-version handoff.
: "${GENUS_MODULE:=genus/211/21.18.000}"          # -> /apps/GENUS211/21.18.000/tools/bin/genus
: "${INNOVUS_MODULE:=innovus/211/21.18.000}"      # -> /apps/INNOVUS211/21.18.000/bin/innovus
: "${XCELIUM_MODULE:=xcelium/2403/24.03.005}"     # -> /apps/XCELIUM2403/24.03.005/tools/bin/xrun
: "${VERISIUM_MODULE:=verisiumdebug/2403/24.03.001}"  # -> /apps/VDEBUG2403/24.03.001/tools/bin/verisium
: "${PEGASUS_MODULE:=pegasus/232/23.24.000}"      # -> /apps/PEGASUS232/23.24.000/bin/pegasus
: "${SSV_MODULE:=ssv/251/25.12.000}"              # -> /apps/SSV251/25.12.000/bin/tempus
: "${ASSURA_MODULE:=assura/41/618/04.17.001}"     # -> /apps/ASSURA41/04.17.001-618/tools/bin/assura

# ---- PDK: gsclib045 -------------------------------------------------------
# GPDK045 itself is analog only and ships no digital standard cells. The
# digital kit is gsclib045, a separate IP library underneath it. That is why
# the path is this deep.
: "${GSCLIB:=/process/hosted/gpdk/gpdk045/ip_libraries/gsclib045/v4p4/gsclib045}"

# Liberty timing. Two corners: slow/1.0V/125C signs off SETUP, fast/1.0V/-40C
# signs off HOLD. (The kit also ships vdd1v2 variants; we use the 1.0V set.)
: "${LIB_SS:=$GSCLIB/timing/slow_vdd1v0_basicCells.lib}"
: "${LIB_FF:=$GSCLIB/timing/fast_vdd1v0_basicCells.lib}"

# Physical abstract views for place and route.
: "${LEF_TECH:=$GSCLIB/lef/gsclib045_tech.lef}"
: "${LEF_MACRO:=$GSCLIB/lef/gsclib045_macro.lef}"

# Behavioural Verilog models of the standard cells. Step 04 links your
# synthesized netlist against these.
: "${STDCELL_V:=$GSCLIB/verilog/slow_vdd1v0_basicCells.v}"

# Transistor-level netlist of the standard cells. Step 10 compares against it.
: "${STDCELL_CDL:=$GSCLIB/cdl/gsclib045.cdl}"

# Cell layout, merged into your GDS at streamOut so the result is a complete
# layout rather than a frame full of references to cells that are not in it.
: "${STDCELL_GDS:=$GSCLIB/gds/gsclib045.gds}"

# GDS layer-number map for streamOut.
: "${STREAM_MAP:=/process/hosted/gpdk/gpdk045/oa/v6p0/soce/streamOut.map}"

# Assura rule decks for steps 09 and 10. These live under the gpdk045 OA tree,
# not under gsclib045.
: "${ASSURA_DIR:=/process/hosted/gpdk/gpdk045/oa/v6p0/assura}"
: "${ASSURA_DRC_RUL:=$ASSURA_DIR/assuraDRC.rul}"
: "${ASSURA_EXT_RUL:=$ASSURA_DIR/extract.rul}"
: "${ASSURA_CMP_RUL:=$ASSURA_DIR/compare.rul}"

# Python 3.6.0 lives here and is not on the default PATH. /bin/python is 2.7.5,
# so the golden-model generator in step 01 must be invoked through this.
: "${PE_PYTHON:=/grid/common/bin/python3}"

# ---- Bootstrap module() in non-interactive bash ---------------------------
# The chamber logs you into csh and defines `module` as a csh function, which
# does not survive into a bash subshell. Every chamber this has run on exports
# MODULESHOME, so sourcing $MODULESHOME/init/bash re-creates the bash version.
# Verified: MODULESHOME=/apps/modules-v3.2.6a-64bit/Modules.
if ! type module >/dev/null 2>&1; then
    if [[ -n "${PE_MODULE_INIT:-}" ]] && [[ -f "$PE_MODULE_INIT" ]]; then
        # shellcheck disable=SC1090
        source "$PE_MODULE_INIT"
    elif [[ -n "${MODULESHOME:-}" ]] && [[ -f "${MODULESHOME}/init/bash" ]]; then
        # shellcheck disable=SC1090
        source "${MODULESHOME}/init/bash"
    fi
fi

# ---- Work area ------------------------------------------------------------
mkdir -p "$PE_WORK" "$PE_LOGS" 2>/dev/null || true
if [[ ! -w "$PE_WORK" ]]; then
    echo "WARN: $PE_WORK not writable; falling back to $PE_FAST (wiped on reboot)" >&2
    PE_WORK="$PE_FAST"; PE_LOGS="$PE_WORK/logs"
    mkdir -p "$PE_WORK" "$PE_LOGS" 2>/dev/null
fi

export PE_ROOT PE_WORK PE_LOGS PE_FAST
export GSCLIB LIB_SS LIB_FF LEF_TECH LEF_MACRO STDCELL_V STDCELL_CDL
export STDCELL_GDS STREAM_MAP ASSURA_DIR ASSURA_DRC_RUL ASSURA_EXT_RUL ASSURA_CMP_RUL
export PE_PYTHON

# ---- pe_require_tool <MODULE_SPEC> <binary> -------------------------------
# Load a module and verify the binary actually lands on PATH.
#
# Two steps, in this order. /apps/<TOOL> is an AUTOFS mount:
# the software appears only when something touches the path. `module load`
# therefore returns 0 even on a node where the tool is not served, and a bare
# `ls /apps` before loading UNDER-reports what exists. The only meaningful test
# is load-then-resolve, in that order.
pe_require_tool() {
    local spec="${1:?pe_require_tool: missing module spec}"
    local bin="${2:?pe_require_tool: missing binary name}"

    if ! type module >/dev/null 2>&1; then
        echo "ERROR: 'module' is not available in this shell." >&2
        echo "       run chamber-diagnose. If it cannot find the module system," >&2
        echo "       set PE_MODULE_INIT=/path/to/init/bash in ~/.longhorn/pe.env" >&2
        return 1
    fi

    module load "$spec" 2>/dev/null

    if ! command -v "$bin" >/dev/null 2>&1; then
        local host="${HOSTNAME:-$(hostname 2>/dev/null || echo unknown)}"
        local class="unknown"
        case "$host" in
            ae[0-9]*ut[0-9]*) class="LOGIN node" ;;
            ip-*)             class="compute node" ;;
        esac
        cat >&2 <<EOF
ERROR: '$bin' did not resolve after loading $spec.
Host:  $host  ($class)

/apps/<TOOL> is autofs. Either this node's map does not carry $spec (the farm
is not uniform), or the mount idled out, or you are on the login node.

Fix:   qsh -q normal.q -now n -V     # fresh compute shell, then retry
       chamber-diagnose              # full probe
EOF
        return 1
    fi
    return 0
}

# ---- pe_rundir <step> -----------------------------------------------------
# Mint $PE_WORK/<step>/<UTC-runid>/ and repoint <step>/latest at it.
# Batch runs never clobber each other, so you can compare a failing run against
# the last good one instead of losing it. Prints the path.
pe_rundir() {
    local step="${1:?pe_rundir: missing step name}"
    local root="$PE_WORK/$step"
    mkdir -p "$root" || { echo "ERROR: cannot create $root" >&2; return 1; }

    local ts run_id n=1
    ts="$(date -u +%Y%m%d-%H%M%S)"
    run_id="$ts"
    # Plain mkdir (no -p) fails atomically on an existing dir, so it doubles as
    # the collision lock when two runs start in the same wall-clock second.
    until mkdir "$root/$run_id" 2>/dev/null; do
        n=$((n + 1))
        if [[ "$n" -gt 9 ]]; then
            echo "ERROR: could not mint a unique run dir under $root" >&2; return 1
        fi
        run_id="$ts-$n"
    done
    # Single `ln -sfn`, relative target. Do NOT use the temp-symlink + `mv`
    # idiom here: once `latest` points at a directory, mv resolves it and moves
    # the new link INSIDE the old run dir, silently pinning `latest` forever.
    ln -sfn "$run_id" "$root/latest" 2>/dev/null || true
    printf '%s\n' "$root/$run_id"
}

# ---- pe_finish <run-dir> <rc> ---------------------------------------------
# Write a machine-readable PASS/FAIL marker. `latest` tells you which run was
# most recent; STATUS tells you whether that run worked. Two different
# questions, two different files, neither requiring you to grep a tool log.
pe_finish() {
    local dir="${1:?}" rc="${2:?}"
    [[ -d "$dir" ]] || return 0
    local verdict="FAIL"; [[ "$rc" == "0" ]] && verdict="PASS"
    printf '%s  %s  rc=%s\n' "$verdict" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$rc" \
        > "$dir/STATUS" 2>/dev/null || true
    return 0
}
