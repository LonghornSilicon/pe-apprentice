# pe-apprentice

Longhorn Silicon apprentice program. One processing element, specification to
GDS, on the Cadence chamber, in ten weeks.

You write one PE, a single cell of the systolic array inside Lambda's matmul
engine, then push it through every stage of an ASIC flow yourself.

## The flow

Ten steps, numbered to match Cornell ECE 6745 labs 6 and 7, with this chamber's
Cadence tools in place of their Synopsys and Mentor ones.

| Step | Tool | What it does | Week |
|---|---|---|---|
| `01-golden-model` | python3 | Computes what the PE should output | 5 |
| `02-xcelium-rtlsim` | Xcelium | Simulates your RTL | 3, 5 |
| `03-genus-synth` | Genus | RTL to a netlist of standard cells | 7 |
| `04-xcelium-ffglsim` | Xcelium | Simulates the netlist | 7 |
| `05-innovus-pnr` | Innovus | Netlist to a layout | 9 |
| `06-tempus-sta` | Tempus | Timing with the wires that got built | 10 |
| `07-xcelium-baglsim` | Xcelium | Simulates with wire delays | optional |
| `08-voltus-pwr` | Voltus | Power from switching activity | optional |
| `09-drc` | Assura | Is the layout manufacturable | 10 |
| `10-lvs` | Assura | Is the layout the circuit you drew | 10 |

Each step directory holds a `README.md` with the exact commands for that step.
Start there, not here.

Every step follows the same shape: run the tool by hand first, one command at a
time, then save what worked into a `run` script. You write those scripts
yourself as you go.

You work inside the step directory and its output stays there. Step 04 reads
`../03-genus-synth/post-synth.v`. That is the whole dependency model.

## Start here

1. `docs/00-chamber-and-repo-setup.md`
2. `docs/longhorn-silicon-apprentice-program.md`
3. Your week's handout in `docs/`, which points you at the step to work through

## Files

| Path | What |
|---|---|
| `rtl/pe.sv` | Yours. Ports and MAC given, you write the three always blocks. |
| `rtl/fxp.sv` | Given. Q8.8 add and multiply. |
| `rtl/pe_array_2x2.sv` | Given. Four of your PEs in a grid, for weeks 9 and 10. |
| `vendor/pe_vendor_drop.sv` | A PE someone else wrote. Week 5. |
| `tools/setup.sh` | Source once per session. Loads tools, sets PDK paths. |

## Technology

gsclib045, the Cadence generic 45 nm standard-cell library on the chamber.
Lambda tapes out on TSMC N16FFC, which is under NDA and not on this chamber.

## For leads

Answer keys, the reference PE, and the defect list are in the private
`pe-apprentice-staff` repository.
