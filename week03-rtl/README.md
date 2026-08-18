# Week 3: Write the PE

**Goal:** Turn your week 2 spec into working, simulated SystemVerilog.

**The file you write is `rtl/pe.sv`.** It is the only file you write all
semester. Everything else is given to you.

## 1. Get on the chamber

```bash
bash
qsh -q normal.q -now n -V
bash
source ~/pe-apprentice/setup.sh
```

Every session. If you skip this, `xrun` will not be found.

## 2. Look at what you are filling in

```bash
cd ~/pe-apprentice
less rtl/pe.sv
```

The ports, the two weight registers, and the multiplier and adder are already
wired up. You fill in the three `always` blocks marked `TODO`.

The multiplier and adder come from here:

```bash
less rtl/fxp.sv
```

## 3. Look at the test

```bash
less rtl/pe_smoke_tb.sv
```

Four checks:

1. every output is 0 after reset
2. `2.0 * 3.0 + 1.0` gives `7.0`
3. a weight that is loaded but **not** switched in does not change the answer
4. after `pe_switch_in`, the new weight does change the answer

Check 3 is the important one. It is the entire reason the PE has two weight
registers, and it is the one most people get wrong.

## 4. Write it

Open `rtl/pe.sv` and fill in the three `always` blocks.

```bash
vi ~/pe-apprentice/rtl/pe.sv
```
timing diagrams, not from memory of code you have seen.

Three rules:

- Use `logic`. Not `wire`, not `reg`.
- `=` inside `always_comb`. `<=` inside `always_ff`. Never the other way round.
- Every flop gets a value in the `rst` branch. Every single one. A flop you
  forget is `X` in simulation and unknown at power-up in silicon.

If you cannot answer a question from your week 2 notes, that is a gap in your
spec. Go fix the spec first, then come back.

## 5. Simulate

```bash
cd ~/pe-apprentice/week03-rtl
xrun -sv -access +rwc \
    ../rtl/fxp.sv \
    ../rtl/pe.sv \
    ../rtl/pe_smoke_tb.sv
```

`-sv` says the files are SystemVerilog. `-access +rwc` lets the waveform viewer
read every signal; leave it off and your waveform comes up empty. Compile,
elaborate, and simulate all happen in this one command.

You are looking for:

```bash
=== 1. reset leaves every output defined ===
  [ ok ] pe_psum_out                    0 (0.0000)
  ...
 SMOKE TEST PASSED, 0 errors
```

Keep going until you get it. The failure lines tell you what was expected and
what you produced.

## 6. Look at the waveform

```bash
simvision waves.shm &
```

SimVision opens with an **empty waveform pane and a time axis reading
0 to 1,000,000,000 ns**. That is the default, not a bug. Five clicks to fix it:

1. Click **`dut`** in the Design Browser tree on the left.
2. Signal names appear in the lower pane.
3. Ctrl-click the ones you want: `pe_switch_in`, `pe_psum_out`,
   `pe_accept_w_in`, `pe_valid_in`, `weight_bg`, `weight_active`.
4. Click the down-arrow button at the bottom, **Click and add to waveform area**.
5. **View > Zoom > Full** to rescale the axis to your actual 110 ns.

Now step through check 3. You should see `pe_weight_in` go to 768 (3.0) around
20 ns, then 1280 (5.0) around 65 ns, with `pe_switch_in` pulsing between them.

Compare it to your week 2 timing diagram 2. If they disagree, one of them is
wrong. Work out which one before you change any code. Sometimes it is the
diagram, and that is worth knowing.

## 7. Save the command

Now that it works, put it in a script so you never type it again.

```bash
cd ~/pe-apprentice/week03-rtl
vi run
```

`i` to start typing, `Esc` to stop, `:wq` to save and quit, `:q!` to bail
without saving. There is no VS Code on the chamber. `SETUP.md` has the rest.

Put this in:

```bash
#!/usr/bin/env bash
xrun -sv -access +rwc \
  ../rtl/fxp.sv \
  ../rtl/pe.sv \
  ../rtl/pe_smoke_tb.sv
```

Then:

```bash
chmod +x run
./run
```

Every tool week from here works this way: get it right by hand, then save it.
A script you wrote before you understood it is a script you cannot debug.

## Turn in

```bash
cd ~/pe-apprentice
git add rtl/pe.sv week03-rtl/run
git commit -m "week 3: pe.sv"
git bundle create ~/<your-username>-week3.bundle main..<your-username>
```

Move the bundle off the chamber, plus a screenshot of the passing test with the
waveform open.

## Done means

- All four checks pass, 0 errors
- Nothing renamed
- `./run` works from a fresh shell
- You can say whether you made the weight promotion combinational or sequential,
  and what that does to your answer to week 2 question 5a
