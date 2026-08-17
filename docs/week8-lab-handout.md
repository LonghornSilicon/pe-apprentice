# Week 8 Lab: Before You Place and Route

*Week 8 of 11. Handout.*

**Goal:** Understand floorplanning and placement before you run an automated tool that will make those decisions for you.

**Before you start**
- Read: the Physical Design section of [the SemiAnalysis EDA Primer](https://newsletter.semianalysis.com/p/the-eda-primer-from-rtl-to-silicon), specifically Floorplanning, Power Planning, Placement, Routing, and Clock Tree Synthesis.
- Watch: your PD lead's own walkthrough of the floorplan and placement flow, recorded for this week. A short, direct recording of the actual flow you'll use beats a generic public video here, since it's the exact tools and PDK you're working with.

**Background**
Floorplanning decides where things go before anything is actually placed: die size, where major blocks sit, where power delivery runs, where IO pins land. Placement then puts every individual cell in a specific spot within that plan. Get the floorplan wrong and everything downstream gets harder: wires get longer, congestion builds up in tight spots, and power delivery gets uneven. Fixing a bad floorplan after routing is far more expensive than fixing it before placement even starts.

**Tasks**
1. Read and watch the material above.
2. Handwritten floorplan sketch for your PE array: where would you place the PEs relative to each other given how data actually flows between them, where would power straps run, where would IO pins land.
3. Notes: name at least 2 real things that go wrong with a bad floorplan, and explain why catching them now is cheaper than catching them at routing.

**Deliverable**
Floorplan sketch and notes. One PDF.

**Done means**
- Floorplan sketch shows a real layout choice with reasoning behind cell and power placement, not just a rectangle with PEs scattered in it
- Notes correctly name at least 2 real risks (congestion, IR drop, or long critical nets are the usual ones)
