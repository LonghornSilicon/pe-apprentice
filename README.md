# pe-apprentice

Longhorn Silicon apprentice program. One processing element, specification to
GDS, on the Cadence chamber, in ten weeks.

You write a single PE, one cell of the systolic array inside Lambda's matmul
engine, then push it through every stage of an ASIC flow yourself: RTL,
verification, synthesis, gate-level verification, place and route, timing
signoff, power, DRC, LVS.

## The flow

Ten steps, modeled on Cornell ECE 6745 labs 6 and 7, with the tools swapped for
this chamber's all-Cadence stack.

| Step | Cornell equivalent | Tool here | In | Out |
|---|---|---|---|---|
| `01-golden-model` | 01-pymtl-rtlsim | Python | spec | test vectors, expected outputs |
| `02-xcelium-rtlsim` | 02-synopsys-vcs-rtlsim | Xcelium | `pe.sv` | pass/fail, waveform |
| `03-genus-synth` | 03-synopsys-dc-synth | Genus | `pe.sv`, `constraints.sdc` | `pe_synth.v`, timing/area/power |
| `04-xcelium-ffglsim` | 04-synopsys-vcs-ffglsim | Xcelium | `pe_synth.v`, cell models | pass/fail on gates |
| `05-innovus-pnr` | 05-cadence-innovus-pnr | Innovus | `pe_synth.v`, LEF | `pe_pnr.v`, `.spef`, `.sdf`, `.gds` |
| `06-tempus-sta` | 06-synopsys-pt-sta | Tempus | `pe_pnr.v`, `.spef`, `.sdc` | setup and hold slack |
| `07-xcelium-baglsim` | 07-synopsys-vcs-baglsim | Xcelium | `pe_pnr.v`, `.sdf` | pass/fail with wire delay, `.saif` |
| `08-voltus-pwr` | 08-synopsys-pt-pwr | Voltus | `.saif`, `.spef` | power breakdown |
| `09-drc` | 09-mentor-calibre-drc | see note | `pe.gds` | `drc.rpt` |
| `10-lvs` | 10-mentor-calibre-lvs | see note | `pe.gds`, `pe_pnr.v` | `lvs.rpt` |

Cornell runs steps 1 through 4 as lab 6 and 5 through 10 as lab 7. Same split
here: steps 1 through 4 are the front end, 5 through 10 the back end.

Steps 09 and 10 are unassigned pending a license check. gsclib045 ships Assura
and Diva rule decks, not Pegasus. See `docs/00-chamber-and-repo-setup.md`.

## Running it

Every step directory holds a `run` script. Call it from anywhere:

```
% ./02-xcelium-rtlsim/run
% ./02-xcelium-rtlsim/run --waves
% ./03-genus-synth/run --shell
```

Cornell's convention, which we keep: you run each tool interactively first, one
command at a time, and only then use the script. `--shell` opens the tool with
the environment set up and nothing else done for you.

Two properties of the run system:

Tool output goes to `$PE_WORK` (`~/work/pe`), never into this repo. A git
checkout cannot destroy a run and a run cannot dirty your git status.

Each run gets a timestamped directory, so a failing run never overwrites the
last good one. `<step>/latest` points at the most recent run. `<step>/<run-id>/
STATUS` says PASS or FAIL with a return code. Which run was last and whether it
worked are separate questions with separate answers.

## Start here

1. `docs/00-chamber-and-repo-setup.md`. Chamber access, setup, and the checks
   that must pass before week 2.
2. `docs/longhorn-silicon-apprentice-program.md`. The syllabus.
3. Your week's handout in `docs/`.

## Files

| Path | What |
|---|---|
| `rtl/pe.sv` | Yours. Ports and MAC given, you write the always blocks. |
| `rtl/pe_array_2x2.sv` | Given. Four of your PEs wired into an array. Weeks 8 to 10. |
| `rtl/fxp.sv` | Given. Q8.8 fixed-point add and multiply. |
| `vendor/pe_vendor_drop.sv` | A PE someone else wrote. Week 5 target. Read the header, not the body. |
| `0N-*/run` | One script per flow step. |
| `tools/` | Module pins, PDK paths, `chamber-diagnose`. |

## Technology

Everything targets **gsclib045**, the Cadence generic 45 nm standard-cell
library on the chamber. It ships Liberty timing, LEF abstracts, behavioural
Verilog models, a transistor-level CDL netlist, and cell GDS, which covers the
whole flow.

Lambda tapes out on TSMC N16FFC, which is under NDA and not on this chamber.
gsclib045 stands in for it.

Tool versions and PDK paths live in `tools/lib/pe-env.sh`. Do not write a path
anywhere else.

## For leads

Answer keys, the reference PE, the planted-defect list, and rubrics are in the
private `pe-apprentice-staff` repository. Nothing here points at them.
