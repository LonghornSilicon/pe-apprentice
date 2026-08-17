# Longhorn Silicon Apprentice Syllabus, 11 Weeks

*Master index. Start here.*

Each technical phase pairs a learn week (reading or video plus handwritten notes) with an execute week (real technical output). Week 1 is the exception, the whole picture before any single piece. Demo day is week 11, doubling as buffer if anything slips.

Start with `00-chamber-and-repo-setup.md`, before week 2, not optional. Every week's handout and staff answer key downloads separately below.

Three placeholders in the setup and later handouts still need a PD lead's real values before this goes out: the setup script path and PDK module name in the setup doc, the `.lib`/`.lef` paths that show up again in weeks 7, 9, and 10, and the DRC/LVS tool name in weeks 9 and 10, which depends on which PDK you land on.

| Week | Phase | Reading / Video | Deliverable |
|---|---|---|---|
| 1 | Silicon design lifecycle overview | [The EDA Primer, From RTL to Silicon](https://newsletter.semianalysis.com/p/the-eda-primer-from-rtl-to-silicon), SemiAnalysis | Name every stage in order with in/out for each, one page diagram mapping our 4 teams onto the flow and marking where the PE sits |
| 2 | RTL and architecture, learn | [Timing Diagrams Explained](https://www.youtube.com/watch?v=AUGRBhfAabY), EEVblog. [Verilog reference](https://chipverify.com/verilog), chipverify.com | Handwritten notes and block/timing diagrams of the PE interface |
| 3 | RTL, execute | - | Working `pe.sv`, simulated, passes the provided smoke test |
| 4 | Verification, learn | [Self Checking Testbench](https://chipverify.com/verification/self-checking-testbench), chipverify.com | Handwritten test plan, corner cases, testbench block diagram |
| 5 | Verification, execute | - | Self-checking testbench run against your RTL, bug log |
| 6 | Synthesis, learn | [Basic Static Timing Analysis, Analyzing Timing Reports](https://www.youtube.com/watch?v=Hxq1Xmr4Rpw), Cadence. Physical Design section of the SemiAnalysis primer | Handwritten notes on timing closure, draft SDC constraints, critical path prediction |
| 7 | Synthesis, execute | - | Synthesis run, area and timing report, prediction checked against the real result |
| 8 | Place and route, learn | Physical Design section of the SemiAnalysis primer, plus a PD lead's own floorplan/placement walkthrough | Handwritten floorplan sketch and notes |
| 9 | Place and route, execute | - | Routed design, updated timing report, ECO list if violations remain |
| 10 | Physical verification and signoff | Signoff section of the SemiAnalysis primer | DRC and LVS clean GDS |
| 11 | Demo day / buffer | - | Present full spec-to-GDS flow, submit final package |

Full handouts exist for every week, including staff-only answer keys for weeks 2, 4, 6, 8, and 10, the weeks with an objectively checkable deliverable.

Reference PE has 2 real bugs: the weight double-buffer swap is a no-op, and `pe_psum_out` never gets reset. Fix before handing this out as a golden reference, or let week 4 to 5 verification catch them for real.
