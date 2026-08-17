# Week 2 Lab: PE Architecture and Interface Specification

*Week 2 of 11. Handout.*

**Goal:** Understand exactly what the PE is supposed to do, and how to read a timing diagram, before writing a single line of RTL.

**Before you start**
- Watch: [EEVblog #1249, Timing Diagrams Explained](https://www.youtube.com/watch?v=AUGRBhfAabY). Do this first. You cannot do this lab without knowing how to read a waveform.
- Reference: [chipverify.com Verilog tutorials](https://chipverify.com/verilog), for syntax questions only, not to copy structure from.
- Have open: the PE port list below. No other reference code.

**Background**
Lambda's compute core is a grid of small units called PEs (processing elements), wired together in a grid. Each PE does one simple job, over and over: take in a number, multiply it by a weight it's holding, add that to a running total handed to it by its neighbor, and pass everything along to the next PE. The weight matters a lot, and swapping in a new weight without stopping the whole grid is the trickiest part of the design. That's why each PE actually holds two copies of the weight: one it's using right now, and one quietly waiting in the background until it's told to swap.

A timing diagram is how you show what a signal does, cycle by cycle, against the clock. Every row is a signal. Every column is a clock cycle. If you can't draw one yet, watch the video above again before starting the tasks.

**PE interface**
```
input  clk, rst
input  signed [15:0] pe_psum_in, pe_weight_in
input  pe_accept_w_in
input  signed [15:0] pe_input_in
input  pe_valid_in, pe_switch_in, pe_enabled
output signed [15:0] pe_psum_out, pe_weight_out, pe_input_out
output pe_valid_out, pe_switch_out
```

**Tasks**
1. Port by port write up. For every port, one plain sentence: what it does and when it changes.
2. Timing diagram 1: reset. Show at least 4 clock cycles, including the moment reset happens.
3. Timing diagram 2: weight preload and switch. Show a new weight loading into the background register while the PE is still computing with the old one, then show the switch.
4. Timing diagram 3: steady streaming. Show 3 back to back valid inputs flowing through.
5. Answer these in writing, in plain terms:
   - A new weight and a switch signal both show up on the same clock cycle. What happens?
   - The valid signal drops for one cycle in the middle of streaming, then comes back. What happens to the output that cycle?
   - Right after reset, the PE is turned on but nothing valid has come in yet. What should the output be? Why?

**Deliverable**
Photo or scan of your handwritten notes and all 3 diagrams, one PDF, uploaded by [day/time]. No typed diagrams, no code.

**Done means**
- Every port has a correct, plain explanation
- All 3 diagrams show the right signal behavior, cycle by cycle
- All 3 written answers point to specific signals, not a vague guess
