# Week 10: Signoff

**Goal:** Prove the layout meets timing with measured wire delays, obeys the
foundry's manufacturing rules, and matches the circuit you meant to build.

**Not written yet.** This handout is still being finished.

## What it will cover

Three checks, three different questions.

**Timing**, with Tempus. Does the design run at the speed you claimed, using the
resistance and capacitance measured off the wires that actually got built.
Innovus gave you its opinion in week 9; Tempus is the signoff tool.

**DRC**, with Assura. Can the geometry be manufactured at all. Minimum spacing,
minimum width, layer overlaps. These rules come from the foundry because
lithography has physical limits.

**LVS**, with Assura. Is the layout the circuit you drew. It pulls a transistor
netlist out of your polygons and compares it against your netlist. It catches
shorts you drew by accident and connections you never drew. A design can pass
DRC and still be completely wrong.

Assura and the gpdk045 rule decks are confirmed present on the chamber. The
runsets are what is missing. Ask a lead where it stands.
