# pe-apprentice

You write one processing element and take it all the way to a GDS: a real chip
layout, on the same Cadence tools the Lambda team uses.

## Where things are

**All Verilog lives in `rtl/`.** The only file you write is `rtl/pe.sv`.

```bash
rtl/
  pe.sv                 <-- YOU WRITE THIS, in week 3
  fxp.sv                given: fixed-point add and multiply
  pe_smoke_tb.sv        given: the week 3 test
  pe_vendor_drop.sv     given: a PE someone else wrote, for week 5
                        (week 5's own scaffold lives in week05-verification/)
  pe_array_2x2.sv       given: four of your PEs in a grid. Optional stretch.
```

**One folder per week.** Each has a `README.md` that is that week's lab handout.
Do them in order.

| Folder | Week | What you do | Tool |
|---|---|---|---|
| `week01-overview/` | 1 | Read about the whole chip design flow | none |
| `week02-spec/` | 2 | Write the PE's specification and timing diagrams | none |
| `week03-rtl/` | 3 | **Write `rtl/pe.sv`** and simulate it | Xcelium |
| `week04-test-plan/` | 4 | Plan how to break it | none |
| `week05-verification/` | 5 | Build a six-component testbench, hunt bugs | Xcelium |
| `week06-timing/` | 6 | Learn timing, predict your slow path | none |
| `week07-synthesis/` | 7 | Turn your RTL into gates | Genus |
| `week08-floorplan/` | 8 | Plan the physical layout | none |
| `week09-pnr/` | 9 | Place and route it | Innovus |
| `week10-signoff/` | 10 | Timing, DRC, LVS | Tempus, Assura |
| `week11-demo/` | 11 | Present it | none |

Weeks with no tool are reading and paper. Weeks with a tool are hands on the
chamber. They alternate on purpose: you learn the idea, then you do it.

## First thing

Read `SETUP.md` and get the chamber working. Do that before week 2.

## How each tool week works

Same shape every time:

1. Run the tool by hand, one command at a time, and look at what happens.
2. Once it works, save the commands into a `run` script in that week's folder.
3. From then on, `./run` repeats it.

You build those scripts yourself. Nothing is handed to you finished.

Each week works inside its own folder. Week 9 reads
`../week07-synthesis/post-synth.v`. That is the whole dependency model.

---

The structure of this program owes a lot to Cornell's ECE 6745 and Berkeley's
EECS 151, both of which put students in front of real tools early and let the
flow do the teaching.
