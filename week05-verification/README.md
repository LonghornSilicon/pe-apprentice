# Week 5: Build the Testbench, Find Real Bugs

**Goal:** Build a self-checking testbench out of six named components, use it on
your own PE, then use it on a PE somebody else wrote.

A testbench you have never seen fail is not a testbench, it is a hope. You have
no evidence it would catch anything, because it has never had to. So this week
ends by pointing yours at a PE with known defects and finding out.

## The week in two halves

**Half A**, most of the week. You build a testbench out of six components in
plain SystemVerilog, run it on your own PE, then run it on a PE somebody else
wrote and find their bugs. This is the graded part.

**Half B**, the last session. You are handed *the same testbench* written in real
UVM, the verification library the industry actually uses. You read it beside
what you built, write one piece of it, and run it.

Half B is short on purpose. UVM is genuinely large; teams give new engineers a
month with it and even then they use about a fifth of it. You are not learning
UVM this week. You are building the ideas UVM is made of, and then seeing what
they look like once a real framework wraps them, so the vocabulary and the shape
are familiar the first time you meet it for real.

## The six components

Every industrial verification environment is built from these six, whatever
framework is around them.

| Component | Job | UVM name |
|---|---|---|
| Generator | invents operations to try | `uvm_sequence` |
| Driver | turns an operation into pin wiggles | `uvm_driver` |
| Monitor | watches the DUT, drives nothing | `uvm_monitor` |
| Model | says what the answer should be | reference model |
| Scoreboard | compares, counts, reports | `uvm_scoreboard` |
| Coverage | says whether you tested enough | `covergroup` |

```
  ┌────────────┐              ┌────────────┐                ┌──────────┐
  │ GENERATOR  │─ gen2drv ───►│   DRIVER   │─── pins ──────►│   DUT    │
  │            │              │            │                │  pe.sv   │
  │ invents    │  a mailbox   │ wiggles    │                │          │
  │ operations │              │ pins       │                └────┬─────┘
  └────────────┘              └─────┬──────┘                     │
                                    │                            │ pins
                                    │ drv2scb                    ▼
                                    │ "here is what        ┌──────────┐
                                    │  I sent"             │ MONITOR  │
                                    │                      │          │
                                    │                      │ watches, │
                                    │                      │ drives   │
                                    │                      │ nothing  │
                                    │                      └────┬─────┘
                                    │                           │ mon2scb
                                    │                           │ "here is what
                                    │                           │  came back"
                                    ▼                           ▼
                          ┌──────────────────────────────────────────┐
                          │              SCOREBOARD                  │
                          │                                          │
       ┌─────────┐        │   expected = MODEL.step(what I sent)     │
       │  MODEL  │───────►│   if (what came back != expected)        │
       │         │        │       count an error and print why       │
       │ the spec│        │                                          │
       │ in code │        └──────────────────────────────────────────┘
       └─────────┘
```

Read it left to right. A transaction is invented, driven onto pins, observed
coming back out, and checked against what the model said it should be. Nobody
looks at a waveform unless something failed.

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

## 8. Save your commands, and mark the end of Half A

Everything above is the graded part of this week. Half B below is one session
and it is not graded on correctness, only on whether you did it and answered the
three questions.


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

---

# Half B: the same testbench, in real UVM

You have built the six ideas. Now look at what they turn into when a real
framework wraps them.

## 9. Read it

```bash
less uvm/pe_uvm_tb.sv
```

One file, about 350 lines. A production UVM environment is eight or nine
separate files plus a package; this is all of it in one place so you can read it
top to bottom in a sitting. Nothing in it is faked or simplified.

Read it with your own testbench open beside it. Every section is numbered to
match, and the comment above each one says what changed and why.

| Yours (Half A) | UVM | What the extra layer buys |
|---|---|---|
| `pe_txn` class | `pe_item extends uvm_sequence_item` | factory registration; free print, copy, compare |
| `generator` task | `pe_seq extends uvm_sequence` | many sequences can share one driver |
| `driver` task | `pe_driver extends uvm_driver` | a two-way handshake, so a sequence can react to the DUT |
| `monitor` task | `pe_monitor extends uvm_monitor` | broadcasts to any number of listeners, not one mailbox |
| `scoreboard` task | `pe_scoreboard extends uvm_subscriber` | subscribes to a broadcast rather than being wired to one source |
| your `initial` block | `pe_env` + `pe_test` | stimulus swaps without touching any other file |
| signals in the module | `interface` + `uvm_config_db` | components four levels deep get a handle without every layer passing it down |

**The one thing that did not change is `pe_model`.** Your reference model drops
into the UVM scoreboard unmodified. That is worth sitting with: the model is
design knowledge and it is the valuable part, while everything around it is
plumbing and it is replaceable.

## 10. Write the sequence

One `TODO(week5)` in that file, in `pe_seq::body()`. Five lines.

```bash
vi uvm/pe_uvm_tb.sv
```

Note `pe_item::type_id::create("it")` rather than `new()`. That is the factory:
it looks up which class to actually build, so a test can substitute a different
item type without this line changing. `new()` would hardcode the type.

## 11. Run it

```bash
cd ~/pe-apprentice/week05-verification
xrun -sv -uvm -access +rwc \
    ../rtl/fxp.sv ../rtl/pe.sv \
    uvm/pe_uvm_tb.sv
```

`-uvm` links the UVM library, which ships with Xcelium. You should see UVM's
banner, then a report at the end from your scoreboard's `report_phase`.

The numbers should match what your own testbench reported. Same stimulus, same
model, same DUT. If they do not, one of the two testbenches is wrong and finding
out which is a real debugging exercise.

## 12. Three questions

Answer these in writing. They are the point of Half B and they can only be
answered by someone who built the simple version first.

1. Your driver took transactions with `mailbox.get()`. UVM's uses
   `seq_item_port.get_next_item()` and then `item_done()`. What can a sequence
   do with the second half of that handshake that yours could not?

2. Half A chose which DUT to test with `+define+DUT_VENDOR`, a compile-time
   switch. UVM has the factory instead. If a chip had two hundred tests sharing
   one environment, what does a compile-time switch cost you that a factory
   override does not?

3. Your components found each other by being declared in the same module. UVM's
   use `uvm_config_db` to pass the interface handle. Why does that matter when
   the driver is four levels down a hierarchy that somebody else wrote?

## What this did and did not cover

You have run a real UVM environment and written a piece of one. Plenty is left:
agents, the register abstraction layer, virtual sequences, callbacks, TLM
sockets, and most of the phase list are all real topics you have not touched.

What you do have is the part that transfers. You know what a driver, a monitor,
a sequence, and a scoreboard each do, because you wrote all four yourself before
seeing what the framework does with them.

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
- Your three Half B answers

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
- The UVM version runs and reports the same numbers as yours
- You can say what a driver, a monitor, a sequence, and a scoreboard each do,
  without looking anything up
