# Week 1 Lab: The Whole Chip Design Picture

*Week 1 of 11. Handout.*

**Goal:** See the entire path from idea to shipped chip before we zoom into any single piece of it.

**Before you start**
Read: [The EDA Primer, From RTL to Silicon](https://newsletter.semianalysis.com/p/the-eda-primer-from-rtl-to-silicon) by SemiAnalysis. Read at least through the Physical Design section. The free portion covers the full flow in real depth, this is not a light explainer, take your time with it.

**Background**
A chip starts as an idea and ends up as a physical object smaller than your fingernail, packed with billions of transistors. The primer lays out the 13 stages that get you from one to the other: planning, architecture, RTL design, RTL verification, RTL freeze, firmware and software development, physical design, signoff, tapeout, fabrication and packaging, post silicon validation, system integration, production. Each stage is handled by a different kind of engineer, each one turning the design into something closer to real silicon. This week is just about seeing that whole map. Starting next week, we zoom into one small piece of it, a single PE.

**Tasks**
1. List all 13 stages in order.
2. For each stage, write one sentence: what goes in, what comes out. Example: "Logic synthesis: RTL code goes in, a gate level netlist comes out."
3. Pick any 2 stages and write 2 to 3 sentences each on why a mistake made at that stage gets more expensive to fix the later it's caught. The primer gives you real numbers on mask costs and respin timelines, use them.
4. Draw a one page diagram of the whole flow as boxes and arrows. Label where each of our 4 teams (ARCH, RTL, DV, PD) works in that flow. Mark, specifically, where our PE sits in the picture, and be clear that it's one small piece of Lambda, and Lambda is one small piece of what a real chip company does.

**Deliverable**
One page: your diagram plus the written answers. Photo or scan, one PDF, uploaded by [day/time].

**Done means**
- All 13 stages named and in the correct order
- At least 8 stages have a correct in/out description
- Diagram clearly shows all 4 teams and where the PE sits
