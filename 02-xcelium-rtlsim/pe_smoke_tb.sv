// ============================================================================
// pe_smoke_tb.sv, week 3 smoke test. Given to you; do not edit.
// ----------------------------------------------------------------------------
// This is NOT a verification testbench. It is a smoke test: it proves your PE
// is alive and roughly does the right thing, so you know your week-3 RTL is
// worth debugging further. It checks four things and stops.
//
// It will pass on designs that are still wrong. That is expected and it is the
// whole reason weeks 4 and 5 exist, you build the testbench that actually
// tries to break this thing. A green light here means "keep going," not "done."
//
// Fixed point: Q8.8, so 1.0 is 16'd256. All expected values below are written
// as multiples of ONE so the arithmetic is readable.
// ============================================================================

`timescale 1ns/1ps

module pe_smoke_tb;

    localparam int QI = 8, QF = 8, DW = 16;
    localparam logic signed [DW-1:0] ONE = 16'sd256;   // 1.0 in Q8.8

    logic clk = 0, rst;
    always #5 clk = ~clk;

    logic signed [DW-1:0] pe_psum_in, pe_weight_in, pe_input_in;
    logic                 pe_accept_w_in, pe_valid_in, pe_switch_in, pe_enabled;
    logic signed [DW-1:0] pe_psum_out, pe_weight_out, pe_input_out;
    logic                 pe_valid_out, pe_switch_out;

    pe #(.QI(QI), .QF(QF)) dut (.*);

    int errors = 0;

    task automatic expect_q(input string what,
                            input logic signed [DW-1:0] got,
                            input logic signed [DW-1:0] exp);
        if (got !== exp) begin
            $display("  [FAIL] %-34s expected %0d (%0.4f)  got %0d (%0.4f)",
                     what, exp, real'(exp)/256.0, got, real'(got)/256.0);
            errors++;
        end else begin
            $display("  [ ok ] %-34s %0d (%0.4f)", what, got, real'(got)/256.0);
        end
    endtask

    task automatic tick; @(negedge clk); endtask

    initial begin
        // $shm_* are Cadence built-ins. Guarded so this same file also runs
        // under Icarus if you want to iterate on a laptop before queueing on
        // the chamber (`iverilog -g2012 -DNO_SHM ...`).
`ifndef NO_SHM
        $shm_open("waves.shm");
        $shm_probe("AS");
`endif

        // ---- idle ----
        rst = 1; pe_accept_w_in = 0; pe_valid_in = 0; pe_switch_in = 0;
        pe_enabled = 1; pe_psum_in = '0; pe_weight_in = '0; pe_input_in = '0;
        repeat (2) @(negedge clk);
        rst = 0;

        $display("");
        $display("=== 1. reset leaves every output defined ===");
        // An output that is X here is a flop you forgot to reset. It will not
        // just be X in simulation, it powers up unknown in silicon, and since
        // partial sums chain down a column, one unknown poisons every PE below.
        expect_q("pe_psum_out",   pe_psum_out,   '0);
        expect_q("pe_input_out",  pe_input_out,  '0);
        expect_q("pe_weight_out", pe_weight_out, '0);
        if (pe_valid_out  !== 1'b0) begin $display("  [FAIL] pe_valid_out not 0 after reset");  errors++; end
        if (pe_switch_out !== 1'b0) begin $display("  [FAIL] pe_switch_out not 0 after reset"); errors++; end

        $display("");
        $display("=== 2. stage a weight, switch it in, do one MAC ===");
        $display("    2.0 * 3.0 + 1.0 should be 7.0");
        pe_accept_w_in = 1; pe_weight_in = 3*ONE;  tick;   // stage 3.0
        pe_accept_w_in = 0; pe_switch_in = 1;      tick;   // promote it
        pe_switch_in = 0;
        pe_valid_in = 1; pe_input_in = 2*ONE; pe_psum_in = ONE; tick;
        tick;
        expect_q("pe_psum_out", pe_psum_out, 7*ONE);

        $display("");
        $display("=== 3. a staged weight must NOT take effect until switch ===");
        $display("    stage 5.0 mid-stream; the answer must still be 7.0");
        pe_accept_w_in = 1; pe_weight_in = 5*ONE;  tick;   // stage 5.0, no switch
        pe_accept_w_in = 0;
        pe_valid_in = 1; pe_input_in = 2*ONE; pe_psum_in = ONE; tick;
        tick;
        expect_q("pe_psum_out (still old weight)", pe_psum_out, 7*ONE);

        $display("");
        $display("=== 4. now switch; the new weight takes over ===");
        $display("    2.0 * 5.0 + 1.0 should be 11.0");
        pe_switch_in = 1;
        pe_valid_in = 1; pe_input_in = 2*ONE; pe_psum_in = ONE; tick;
        pe_switch_in = 0; tick;
        expect_q("pe_psum_out (new weight)", pe_psum_out, 11*ONE);

        $display("");
        $display("========================================");
        if (errors == 0)
            $display(" SMOKE TEST PASSED, %0d errors", errors);
        else
            $display(" SMOKE TEST FAILED, %0d errors", errors);
        $display("========================================");
        $display("");
        $display("Reminder: passing this does not mean your PE is correct.");
        $display("It means it is worth verifying. That is weeks 4 and 5.");
        $display("");
        $finish;
    end

    // Do not let a hung design run forever in a shared chamber queue.
    initial begin
        #10000;
        $display("[FAIL] timeout, the testbench never reached $finish");
        $finish;
    end

endmodule
