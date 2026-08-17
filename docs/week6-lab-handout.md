# Week 6 Lab: Before You Synthesize

*Week 6 of 11. Handout.*

**Goal:** Understand what synthesis actually does to your RTL, and predict where your design will be slow before you find out for real.

**Before you start**
- Watch: [Basic Static Timing Analysis, Analyzing Timing Reports](https://www.youtube.com/watch?v=Hxq1Xmr4Rpw), Cadence.
- Read: the Physical Design section of [the SemiAnalysis EDA Primer](https://newsletter.semianalysis.com/p/the-eda-primer-from-rtl-to-silicon), specifically Logic Synthesis and the Process Corners part.

**Background**
Synthesis takes your RTL and turns it into an actual netlist of logic gates from a standard cell library. Those gates have real delay. Data has to get from one flip-flop to the next, through whatever combinational logic sits between them, before the next clock edge arrives. The longest such path in your design is the critical path, and it sets the fastest clock speed your design can actually run at. Setup time is the minimum amount of time data needs to be stable before a clock edge. Hold time is the minimum amount of time it needs to stay stable after. Slack is the difference between how long a path is allowed to take and how long it actually takes. Negative slack means you asked for a clock speed your logic cannot deliver.

**Tasks**
1. Watch and read the material above.
2. Handwritten notes, in your own words: what is a critical path, what is slack, what does negative slack actually mean, and what are your real options for fixing it (faster cells, restructuring the logic, relaxing the clock period).
3. Draft SDC style constraints for the PE by hand: a target clock period with a reason behind the number, and which ports are your primary inputs and outputs.
4. Before you run anything, sketch which path through your PE you think will be the critical path, and explain why.

**Deliverable**
Notes, draft constraints, and your critical path prediction. One PDF.

**Done means**
- Setup, hold, and slack explained correctly and in your own words
- Constraint draft has a specific clock period with real reasoning behind it, not a guess
- Critical path prediction is grounded in the actual PE datapath, not a shrug
