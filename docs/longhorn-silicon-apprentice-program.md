# Longhorn Silicon Apprentice Syllabus, 11 Weeks

*Master index. Start here.*

You will write one processing element and take it all the way to a GDS: a real
layout, checked against real manufacturing rules, on the same chamber and the
same tools the people taping out Lambda use every day.

Each technical phase pairs a learn week with an execute week. Learn weeks are
reading or video plus handwritten notes. Execute weeks are tool output. Week 1
is the exception, the whole picture before any single piece. Demo day is week
11, doubling as buffer if anything slips.

Start with `00-chamber-and-repo-setup.md`, before week 2, not optional.

| Week | Phase | Reading / Video | Flow step | Deliverable |
|---|---|---|---|---|
| 1 | Silicon design lifecycle | [The EDA Primer, From RTL to Silicon](https://newsletter.semianalysis.com/p/the-eda-primer-from-rtl-to-silicon), SemiAnalysis | - | Every stage named in order with in/out, one page diagram placing our 4 teams and the PE |
| 2 | RTL and architecture, learn | [Timing Diagrams Explained](https://www.youtube.com/watch?v=AUGRBhfAabY), EEVblog. [Verilog reference](https://chipverify.com/verilog) | - | Handwritten port writeup and 3 timing diagrams |
| 3 | RTL, execute | - | `02` | Working `pe.sv`, passes the smoke test |
| 4 | Verification, learn | [Self Checking Testbench](https://chipverify.com/verification/self-checking-testbench), chipverify.com | - | Handwritten test plan, corner cases, testbench block diagram |
| 5 | Verification, execute | - | `01`, `02` | Golden model, self-checking testbench, bug report on the vendor PE |
| 6 | Synthesis, learn | [Basic Static Timing Analysis](https://www.youtube.com/watch?v=Hxq1Xmr4Rpw), Cadence. Physical Design section of the primer | - | Timing notes, draft SDC, critical path prediction, standard-cell library tour |
| 7 | Synthesis, execute | - | `03`, `04` | Synthesis run, timing and area report, gate-level sim passing, prediction checked |
| 8 | Place and route, learn | Physical Design section of the primer, plus a PD lead's floorplan walkthrough | - | Handwritten floorplan sketch and notes |
| 9 | Place and route, execute | - | `05` | Routed 2x2 array, post-route timing, GDS |
| 10 | Signoff | Signoff section of the primer | `06`, `09`, `10` | Post-route STA, DRC clean, LVS clean |
| 11 | Demo day / buffer | - | - | Present spec to GDS, submit final package |

## The flow

The repository is organized by flow step, not by week. Steps are numbered to
match Cornell's ECE 6745 labs 6 and 7, with this chamber's Cadence tools
substituted for their Synopsys and Mentor ones.

| Step | Tool | What it does |
|---|---|---|
| `01-golden-model` | python3 | Computes what the PE should output, in software |
| `02-xcelium-rtlsim` | Xcelium | Simulates your RTL |
| `03-genus-synth` | Genus | Turns RTL into a netlist of standard cells |
| `04-xcelium-ffglsim` | Xcelium | Simulates the netlist, to prove synthesis kept your design |
| `05-innovus-pnr` | Innovus | Places and routes the netlist into a layout |
| `06-tempus-sta` | Tempus | Checks timing with the wires that actually got built |
| `07-xcelium-baglsim` | Xcelium | Simulates with wire delays back-annotated |
| `08-voltus-pwr` | Voltus | Estimates power from switching activity |
| `09-drc` | Assura | Checks the layout against foundry manufacturing rules |
| `10-lvs` | Assura | Checks the layout matches the circuit you meant to build |

Steps 07 and 08 are not on the required path. Ten weeks does not fit ten steps
plus five learn weeks. They are written and runnable, and week 11 is a good
place to attempt them if you are ahead.

Every step directory holds a `run` script. Run it from anywhere in the repo:

```
% ./02-xcelium-rtlsim/run
```

## What you build on

You write `rtl/pe.sv`. Everything else is given to you:

- `rtl/fxp.sv`, fixed-point add and multiply
- `rtl/pe_array_2x2.sv`, four of your PEs wired into an array, for weeks 8 to 10
- `vendor/pe_vendor_drop.sv`, a PE someone else wrote, for week 5
- the `run` script in every step directory
- `tools/`, the chamber environment

If you find yourself writing a run script or a module header from scratch, stop.
That file should already exist. Get a lead.

## Technology

Everything targets gsclib045, the Cadence generic 45 nm standard-cell library
installed on the chamber. Lambda tapes out on TSMC N16FFC, which is under NDA
and not on this chamber. gsclib045 stands in for it, and the flow is identical.

## For leads

Answer keys for weeks 1, 2, 4, 6, and 8, the reference PE, the planted-defect
list, and rubrics are in the private `pe-apprentice-staff` repository.
