#!/usr/bin/env python3
"""
gen_pe_vectors.py  --  yours. You write this in week 5.

Produces the test vectors your SystemVerilog scoreboard checks against. This is
the golden model: it computes what the PE *should* output, in software, from the
specification.

The one rule that makes this worth doing: derive the expected answer from the
SPEC, not from your RTL. If the model and the design come from the same
understanding, they agree with each other and both can be wrong. That is the
most common way a testbench ends up proving nothing.

Q8.8 fixed point. A value v is stored as the integer round(v * 256).
  1.0 -> 256      2.0 -> 512      0.5 -> 128      -1.0 -> -256

Output format, read by the scoreboard with $fscanf:

    <n_cases>
    <name> <n_steps>
      <accept_w> <weight_in> <switch> <valid> <input_in> <psum_in> <expected_psum_out>
      ... one line per cycle ...

Run it:  ./01-golden-model/run
"""

import sys

QI, QF = 8, 8
DW = QI + QF
ONE = 1 << QF                      # 1.0
MAXV = (1 << (DW - 1)) - 1         # +32767
MINV = -(1 << (DW - 1))            # -32768


def q(x):
    """Real number -> Q8.8 integer."""
    return int(round(x * ONE))


def sat(v):
    """Saturating clamp to Q8.8 range. fxp_add does this; your model must too."""
    return MAXV if v > MAXV else MINV if v < MINV else v


def fxp_mul(a, b):
    """Q8.8 * Q8.8 -> Q8.8. Truncates the low QF bits, same as rtl/fxp.sv.

    Note the >> is an arithmetic shift on negative numbers in Python, which
    matches the RTL's bit-slice of a signed product. If you use // instead you
    will get a different answer for negative products and spend an evening
    finding out why.
    """
    return (a * b) >> QF


def fxp_add(a, b):
    return sat(a + b)


# ---------------------------------------------------------------------------
# TODO(week5): model the PE.
#
# Track the two weight registers and produce, for each cycle, what the PE
# should drive on pe_psum_out. Your week 2 diagrams are the specification.
#
# Questions your model has to answer, and they are the same questions your
# week 2 write-up answered:
#   - when does the background weight capture from pe_weight_in?
#   - what does pe_switch_in promote, and on which cycle does the multiplier
#     see the new value?
#   - what is pe_psum_out when pe_valid_in is low?
#   - what happens to the stored weights when pe_enabled is low?
#   - how many cycles after the inputs does pe_psum_out appear?
#
# If you are unsure of one, that is a gap in your spec, not in this file.
# ---------------------------------------------------------------------------
class PEModel(object):
    def __init__(self):
        raise NotImplementedError("week 5: model the PE here")

    def step(self, accept_w, weight_in, switch, valid, input_in, psum_in):
        """Advance one cycle. Return the pe_psum_out visible after this edge."""
        raise NotImplementedError


# ---------------------------------------------------------------------------
# TODO(week5): build your cases.
#
# One entry per corner case from your week 4 plan. Each is a name and a list of
# per-cycle input tuples. Start with the four the smoke test covers so you can
# check your model against something you already know the answer to, then add
# the cases the smoke test does not cover.
# ---------------------------------------------------------------------------
def cases():
    return [
        # ("reset_defines_outputs", [ ... ]),
        # ("basic_mac",             [ ... ]),
        # ("stage_without_switch",  [ ... ]),
        # ("switch_same_cycle_as_weight", [ ... ]),
        # ("disable_preserves_weight",    [ ... ]),
    ]


def main():
    cs = cases()
    if not cs:
        sys.stderr.write("no cases defined yet, see TODO(week5) in this file\n")
        return 1

    with open("pe_vectors.txt", "w") as f:
        f.write("%d\n" % len(cs))
        for name, steps in cs:
            f.write("%s %d\n" % (name, len(steps)))
            m = PEModel()
            for (aw, w, sw, v, a, p) in steps:
                exp = m.step(aw, w, sw, v, a, p)
                f.write("  %d %d %d %d %d %d %d\n" % (aw, w, sw, v, a, p, exp))

    print("wrote pe_vectors.txt: %d cases" % len(cs))
    return 0


if __name__ == "__main__":
    sys.exit(main())
