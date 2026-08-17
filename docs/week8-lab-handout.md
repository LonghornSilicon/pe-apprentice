# Week 8 Lab: Before You Place and Route

*Week 8 of 11. Handout.*

**Goal:** Understand floorplanning and placement before you run an automated tool that will make those decisions for you.

**You will work in pairs from this week through week 10.** Innovus is heavy and
the chamber is shared with other universities. Pair up now, before the tool week.

**Before you start**
- Read: the Physical Design section of [the SemiAnalysis EDA Primer](https://newsletter.semianalysis.com/p/the-eda-primer-from-rtl-to-silicon), specifically Floorplanning, Power Planning, Placement, Routing, and Clock Tree Synthesis.
- Watch: your PD lead's own walkthrough of the floorplan and placement flow, recorded for this week. A short, direct recording of the actual flow you'll use beats a generic public video here, since it's the exact tools and PDK you're working with.

**Background**
Floorplanning decides where things go before anything is actually placed: die size, where major blocks sit, where power delivery runs, where IO pins land. Placement then puts every individual cell in a specific spot within that plan. Get the floorplan wrong and everything downstream gets harder: wires get longer, congestion builds up in tight spots, and power delivery gets uneven. Fixing a bad floorplan after routing is far more expensive than fixing it before placement even starts.

**Tasks**
1. Read and watch the material above.
2. Handwritten floorplan sketch for `rtl/pe_array_2x2.sv`, four of your PEs
   wired into a 2x2 grid. Read that file's header first; it shows which edges
   carry activations, which carry partial sums, and which carry weights.

   Sketch: where you would place the four PEs relative to each other given how
   data actually moves between them, where the power rings and straps would run,
   and where the IO pins would land on each edge. Activations enter west,
   partial sums leave south. Your pin placement should reflect that.
3. Notes: name at least 2 things that go wrong with a bad floorplan, and explain
   why catching them now is cheaper than catching them at routing.

4. Predict one number: which of the four PEs will have the longest wire to its
   neighbour under your floorplan, and roughly how much longer. Week 9 will tell
   you whether you were right.

**Deliverable**
Floorplan sketch and notes. One PDF.

**Done means**
- Floorplan sketch shows a specific layout choice with reasoning behind cell and
  power placement, not a rectangle with PEs scattered in it
- Pin placement matches the direction data actually flows
- Notes correctly name at least 2 risks (congestion, IR drop, or long critical
  nets are the usual ones)
- You committed to a prediction in task 4
