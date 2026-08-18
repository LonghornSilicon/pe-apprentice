# Week 5: Build the Testbench, Find Real Bugs

**Goal:** Build a self-checking testbench out of six named components, use it on
your own PE, then use it on a PE somebody else wrote.

A testbench you have never seen fail is not a testbench, it is a hope. You have
no evidence it would catch anything, because it has never had to. So this week
ends by pointing yours at a PE with known defects and finding out.

## What you are building

Six components. Each one is a real thing with a real name, and every industrial
verification environment has all six. The names in the right column are what
they are called in UVM, the SystemVerilog verification library used across the
industry. You are not using UVM this week; you are building the six ideas UVM is
made of, in plain SystemVerilog, so that when you meet `uvm_driver` at an
internship you already know what it does.

| Component | Job | UVM name |
|---|---|---|
| Generator | invents operations to try | `uvm_sequence` |
| Driver | turns an operation into pin wiggles | `uvm_driver` |
| Monitor | watches the DUT, drives nothing | `uvm_monitor` |
| Model | says what the answer should be | reference model |
| Scoreboard | compares, counts, reports | `uvm_scoreboard` |
| Coverage | says whether you tested enough | `covergroup` |

```
  generator ──► gen2drv ──► driver ──► [ DUT ] ──► monitor
                              │                       │
                              └──► drv2scb        mon2scb
                                      │               │
                                      ▼               ▼
                                    ┌───────────────────┐
                                    │    scoreboard     │◄── model
                                    └───────────────────┘
```

They talk through **mailboxes**, never by reaching into each other's variables.
That separation is the point. You can swap the generator without touching the
driver, and the monitor can be pointed at an interface you do not drive at all.

## The idea that matters most

Up to now every test you have written was **directed**: you decided the inputs
and you decided the answer. Directed tests find the bugs you thought of.

This week you write **constrained random** stimulus instead. You describe the
space of legal inputs and how often you want each kind, and the simulator picks
the actual values. It will produce combinations you would not have thought to
write, which is exactly why it finds bugs you would not have thought to look for.

The cost is that you no longer know the answer in advance. That is what the
reference model is for, and it is why the two ideas always arrive together.

## 1. Get on the chamber

```bash
bash
qsh -q normal.q -now n -V
bash
source ~/pe-apprentice/setup.sh
cd ~/pe-apprentice/week05-verification
ls
```

Three scaffold files. `pe_tb.sv` includes the other two, so it is the only one
you name on the command line. Read all three before writing anything. Each `TODO(week5)` is one thing for you to fill in and
the comment above it says what question you are answering.

## 2. The transaction

```bash
vi pe_txn.sv
```

A transaction is one operation on the PE: a weight, an activation, a partial
sum, and the four control bits. It says *what* should happen, not how to make it
happen on wires.

The fields are declared `rand`, which lets the simulator pick their values. Your
job is the `constraint` blocks, which tell it which values are legal and how
often you want them.

Two forms do most of the work:

```systemverilog
weight  inside {[-8*ONE : 8*ONE]};      // restrict to a range
valid   dist   { 1 := 9, 0 := 1 };      // 1 about nine times as often as 0
```

Write constraints that answer the four questions in the file's TODO comment.
Your week 4 test plan should already have opinions on all four. Every `dist`
weight you write should have a reason you can say out loud; you will be asked.

**The one to think hardest about.** Week 2 question 5a asked what happens when a
new weight and a switch arrive on the same cycle. If your constraints never
produce that combination, you will never test it, no matter how many transactions
you run. Section 6 will tell you whether you did.

## 3. The reference model

```bash
vi pe_model.sv
```

This is what the PE *should* output, computed in software. Fill in `reset()`
and `step()`.

**Write it from your week 2 spec, not from your RTL.** If the model and the
design come from the same understanding they will agree with each other and both
can be wrong, and your testbench will pass cleanly while proving nothing. Open
`pe.sv` only to check that you and it made the same choice about weight
promotion, not to copy the logic across.

The Q8.8 multiply and add are given, because matching truncation and saturation
bit for bit is fiddly and is not this week's lesson. Read them anyway.

**The mistake almost everyone makes here.** Software runs top to bottom;
hardware does everything at once on the clock edge. If you update `weight_bg`
before you use the foreground weight, you have modelled a PE that does not
exist. The symptom is that everything passes until the first switch and then
every cycle after it is wrong.

## 4. The generator, driver, and scoreboard

```bash
vi pe_tb.sv
```

Three TODOs, in sections 1, 2, and 4 of that file. Each is a handful of lines.
The monitor is given, because its one-cycle timing offset is fiddly and is not
the lesson.

Two things the file's comments tell you and that are worth repeating:

`assert (t.randomize())`. If your constraints contradict each other the solver
cannot find a legal value, `randomize()` returns 0, and without the assert your
testbench silently drives whatever was in the object before and reports a pass.

Drive on `negedge`. The DUT samples on `posedge`, so driving on the same edge it
captures on is a race. It usually works in simulation and it is a real bug.

Your failure message earns its keep or it does not. `t.show()` exists so you can
print the transaction that caused a mismatch. A message that says only
`MISMATCH` is worth nothing at 1am.

## 5. Run it on your own PE

```bash
xrun -sv -access +rwc \
    ../rtl/fxp.sv \
    ../rtl/pe.sv \
    pe_tb.sv
```

You are looking for:

```
 checked : 500
 errors  : 0
 coverage: 94.4%
 PASS
```

Errors mean either your PE is wrong or your model is wrong, and working out
which is the actual skill. Read the failure line: it prints the transaction, the
expected value, and what you got. Then find that moment in the waveform.

```bash
simvision waves.shm &
```

Log every bug you fix, in your RTL or your model, and what you had
misunderstood. A model bug is worth writing down too; it tells you which part of
the spec you had wrong.

## 6. Read your coverage

The number at the end of the run is the fraction of situations you defined as
interesting that your stimulus actually reached. Passing tests say nothing about
what you never tried; this does.

```bash
xrun -sv -access +rwc -covoverwrite -coverage all \
    ../rtl/fxp.sv ../rtl/pe.sv \
    pe_tb.sv
```

Look at your crosses in particular. **If `x_switch_accept` is below 100%, you
have never tested week 2 question 5a**, and 500 passing transactions do not
change that. Go back to section 2, adjust your constraints, and re-run.

Reaching 100% passing with a hole in coverage is the most useful thing this week
can show you, and it is why coverage exists as a separate idea from testing.

## 7. Now the vendor PE

```bash
less ../rtl/pe_vendor_drop.sv
```

Read the header only. Do not read the body.

This is a PE written by someone else, against the same week 2 interface. It has
defects in it. In industry this is routine: blocks arrive from other teams, from
acquisitions, and from IP vendors, with a datasheet and no warranty. You do not
get to assume they work. You get to prove whether they do, with a testbench
built against a spec you understand better than the person who wrote the code.

```bash
xrun -sv -access +rwc +define+DUT_VENDOR \
    ../rtl/fxp.sv ../rtl/pe_vendor_drop.sv \
    pe_tb.sv
```

Your scoreboard should fail. For each distinct defect, produce four things:

1. the transaction that caught it, from the failure line
2. the waveform showing it
3. the sentence of the week 2 spec it violates
4. what you would tell the vendor to change

If it catches nothing, the vendor PE is not the thing that is broken.

Ask yourself one more question, and put the answer in your report: **did random
stimulus find each defect on its own, or did you have to add a directed test?**
If one of them needed a directed test, your constraints were not exploring the
space you thought they were. That is a real finding about your own work.

## 8. Save your commands

```bash
vi run
```

```bash
#!/usr/bin/env bash
xrun -sv -access +rwc -covoverwrite -coverage all \
  ../rtl/fxp.sv ../rtl/pe.sv \
  pe_tb.sv
```

```bash
vi run-vendor
```

```bash
#!/usr/bin/env bash
xrun -sv -access +rwc +define+DUT_VENDOR \
  ../rtl/fxp.sv ../rtl/pe_vendor_drop.sv \
  pe_tb.sv
```

```bash
chmod +x run run-vendor
```

## 9. What UVM adds

You have now built the six ideas by hand. UVM is a SystemVerilog class library
that provides them as base classes you extend, plus three things that only start
to matter at scale:

- **A factory**, so a test can swap in a different driver or sequence without
  editing the testbench that instantiates it. On a chip with hundreds of tests
  reusing one environment, that is the difference between changing one line and
  changing hundreds.
- **Phases**, a fixed order that every component agrees on for build, connect,
  run, and report, so components written by different people compose.
- **A configuration database**, so a component deep in the hierarchy can be
  handed a handle without every layer between passing it down.

None of that earns its keep on a PE with five control signals. All of it earns
its keep on a block with a dozen interfaces and forty engineers. The six ideas
are the same either way, which is why building them by hand first is the faster
route to understanding UVM than starting with UVM.

## Turn in

```bash
cd ~/pe-apprentice
git add week05-verification/
git commit -m "week 5: self-checking testbench and vendor bug report"
git bundle create ~/<your-username>-week5.bundle main..<your-username>
```

Move the bundle off the chamber, plus:

- Your run output on your own PE, showing checks, errors, and coverage
- Your coverage numbers, with a sentence on any cross below 100% and why
- Your bug log: what broke, what you thought was happening, what actually was,
  how you fixed it, and whether the bug was in the RTL or the model
- Your vendor bug report, one entry per defect, in the four-part form above
- Your answer on whether random stimulus found each defect unaided

## Done means

- The testbench reports pass or fail per run automatically, with no waveform
  reading required to know which
- Your model was written from the spec and you can explain `step()` without
  opening `pe.sv`
- Every constraint has a reason you can state
- `x_switch_accept` coverage is 100%, meaning you actually tested week 2
  question 5a
- **Your testbench catches every defect in the vendor PE.** This is binary and
  it is the main thing week 5 is graded on.
