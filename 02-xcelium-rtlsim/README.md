# Step 02: RTL Simulation

**Week 3.** You write `rtl/pe.sv` and simulate it.

By the end of this step you will have a working PE, a passing smoke test, a
waveform you have compared against your own week 2 diagrams, and a `run` script
you built yourself so you can repeat the whole thing with one command.

## 1. Get onto a compute node

The chamber logs you into `csh` on a shared login node. Neither of those is
where you want to work.

```
% bash
% qsh -q normal.q -now n -V
% bash
% source ~/longhorn-apprentice/pe-apprentice/tools/setup.sh
```

Your prompt should now show a hostname like `ip-10-2-6-219`, not `ae03ut01`.
The setup script prints where each tool resolved to. If any says `MISSING`, stop
and get a lead.

Do this every session.

## 2. Look at what you are building

```
% cd ~/longhorn-apprentice/pe-apprentice
% less rtl/pe.sv
```

The ports, the two weight registers, and the multiplier and adder are already
there. You write the three `always` blocks marked `TODO`.

The multiplier and adder come from `rtl/fxp.sv`:

```
% less rtl/fxp.sv
```

These are Q8.8 fixed point: 16-bit signed integers that everyone has agreed to
read with a binary point 8 bits from the right. So `1.0` is stored as `256`,
`2.0` as `512`, and the smallest step is `1/256`. The hardware is ordinary
integer hardware.

## 3. Look at the test

```
% less 02-xcelium-rtlsim/pe_smoke_tb.sv
```

Four checks:

1. every output is `0` after reset
2. `2.0 * 3.0 + 1.0` gives `7.0`
3. a weight loaded but not switched in does **not** change the answer
4. after `pe_switch_in`, the new weight does change the answer

Check 3 is the one that matters. It is the whole reason the PE has two weight
registers, and it is the one most people get wrong.

## 4. Write the PE

Open `rtl/pe.sv` and fill in the three `always` blocks. Work from your own week
2 timing diagrams.

Three rules:

- Use `logic`. Not `wire`, not `reg`.
- `=` inside `always_comb`, `<=` inside `always_ff`. Never the other way round.
- Every flop gets a value in the `rst` branch. Every one. A flop you forget is
  `X` in simulation and unknown at power-up in silicon.

If you cannot answer a question from your week 2 notes, that is a gap in your
spec. Go fix the spec, then come back.

## 5. Simulate

```
% cd ~/longhorn-apprentice/pe-apprentice/02-xcelium-rtlsim
% xrun -sv -xprop=tmerge -access +rwc \
    ../rtl/fxp.sv \
    ../rtl/pe.sv \
    pe_smoke_tb.sv
```

`-xprop=tmerge` keeps unknown values pessimistic instead of letting the
simulator guess. Without it, a flop you forgot to reset can look like it works.
`-access +rwc` lets the waveform viewer see every signal; leave it off and the
waveform is empty.

You should see:

```
=== 1. reset leaves every output defined ===
  [ ok ] pe_psum_out                        0 (0.0000)
  ...
 SMOKE TEST PASSED, 0 errors
```

Keep going until you get that. Read the failure lines; they tell you the
expected value and what you produced.

## 6. Look at the waveform

```
% simvision waves.shm &
```

Find `pe_switch_in`, `pe_psum_out`, and both weight registers. Put them next to
each other and step through check 3.

Compare it against your week 2 timing diagram 2. If they disagree, one of them
is wrong. Work out which before changing any code. Sometimes it is the diagram.

## 7. Build the run script

Now that it works, put the command in a script so you never type it again.

```
% cd ~/longhorn-apprentice/pe-apprentice/02-xcelium-rtlsim
% code run
```

Put this in it:

```bash
#!/usr/bin/env bash
xrun -sv -xprop=tmerge -access +rwc \
  ../rtl/fxp.sv \
  ../rtl/pe.sv \
  pe_smoke_tb.sv
```

Then:

```
% chmod +x run
% ./run
```

Every step from here has a `run` script and you build each one the same way:
get the command working by hand first, then save it. A script you wrote before
you understood it is a script you cannot debug.

## Deliverable

```
% cd ~/longhorn-apprentice/pe-apprentice
% git add rtl/pe.sv 02-xcelium-rtlsim/run
% git commit -m "week 3: pe.sv"
% git bundle create ~/<your-username>-week3.bundle main..<your-username>
```

Transfer the bundle off the chamber, plus a screenshot of the passing smoke test
with the waveform open.

## Done means

- All four checks pass, 0 errors, no unintentional warnings
- No signal renamed
- Your `run` script works from a clean shell
- You can say why you made the weight promotion combinational or sequential, and
  what that does to the answer you gave in week 2 question 5a
