# Week 2: Specify the PE

**Goal:** Understand exactly what the PE does, and learn to read a timing
diagram, before writing any Verilog.

No tools this week. Handwritten only. No typed diagrams, no code.

## Before you start

Watch [EEVblog #1249, Timing Diagrams Explained](https://www.youtube.com/watch?v=AUGRBhfAabY).
Do this first. You cannot do this week without knowing how to read a waveform.

For Verilog syntax questions only, [chipverify.com](https://chipverify.com/verilog).
Do not copy structure from it.

## Background

Lambda's compute core is a grid of small units called PEs, wired together. Each
PE does one job over and over: take a number, multiply it by a weight it is
holding, add that to a running total from its neighbour, and pass everything
along.

The weight matters a lot. Swapping in a new weight without stopping the whole
grid is the trickiest part of the design. That is why each PE holds **two**
copies of the weight: one it is using right now, and one waiting in the
background until it is told to swap.

A timing diagram shows what a signal does, cycle by cycle, against the clock.
Every row is a signal, every column is a clock cycle.

## The interface

Grouped by which side of the PE each signal is on. A PE in the middle of the
grid has neighbours on all four sides.

```systemverilog
input  logic                clk
input  logic                rst             // asynchronous, active high

// north, from the PE above
input  logic signed [15:0]  pe_psum_in
input  logic signed [15:0]  pe_weight_in
input  logic                pe_accept_w_in

// west, from the PE to the left
input  logic signed [15:0]  pe_input_in
input  logic                pe_valid_in
input  logic                pe_switch_in
input  logic                pe_enabled

// south, to the PE below
output logic signed [15:0]  pe_psum_out
output logic signed [15:0]  pe_weight_out

// east, to the PE to the right
output logic signed [15:0]  pe_input_out
output logic                pe_valid_out
output logic                pe_switch_out
```

The 16-bit values are Q8.8 fixed point: 8 bits of integer including the sign, 8
bits of fraction. They are ordinary 16-bit signed integers that everyone agrees
to read with a binary point 8 places from the right. So 1.0 is stored as 256 and
2.0 as 512.

## Do

1. **Port by port.** For every port, one plain sentence: what it does, and when
   it changes.

2. **Timing diagram 1, reset.** At least 4 clock cycles, including the moment
   reset happens.

3. **Timing diagram 2, weight preload and switch.** Show a new weight loading
   into the background register while the PE is still computing with the old one.
   Then show the switch.

4. **Timing diagram 3, steady streaming.** Three back to back valid inputs
   flowing through.

5. **Answer in writing, in plain terms:**
   - A new weight and a switch signal both arrive on the same clock cycle. What
     happens?
   - The valid signal drops for one cycle in the middle of streaming, then comes
     back. What happens to the output that cycle?
   - Right after reset, the PE is on but nothing valid has come in yet. What
     should the output be, and why?

Keep these. You write your Verilog from them next week, and you build your
testbench from them in week 4.

## Turn in

Photo or scan of your handwritten notes and all 3 diagrams. One PDF.

## Done means

- Every port has a correct, plain explanation
- All 3 diagrams show the right behaviour, cycle by cycle
- All 3 written answers point at specific signals, not a vague guess
