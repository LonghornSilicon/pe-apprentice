//------------------------------------------------------------------------
// pe_smoke_tb.sv
//------------------------------------------------------------------------
// Four checks. It will pass on designs that are still wrong, which is why
// weeks 4 and 5 exist. Q8.8, so ONE is 1.0.

`timescale 1ns/1ps

module pe_smoke_tb;

  localparam QI = 8, QF = 8, DW = 16;
  localparam logic signed [DW-1:0] ONE = 16'sd256;

  logic clk = 0, rst;
  always #5 clk = ~clk;

  logic signed [DW-1:0] pe_psum_in, pe_weight_in, pe_input_in;
  logic                 pe_accept_w_in, pe_valid_in, pe_switch_in, pe_enabled;
  logic signed [DW-1:0] pe_psum_out, pe_weight_out, pe_input_out;
  logic                 pe_valid_out, pe_switch_out;

  pe #(QI,QF) dut (.*);

  int errors = 0;

  task automatic expect_q( input string what,
                           input logic signed [DW-1:0] got,
                           input logic signed [DW-1:0] exp );
    if ( got !== exp ) begin
      $display("  [FAIL] %-30s expected %0d (%0.4f)  got %0d (%0.4f)",
               what, exp, real'(exp)/256.0, got, real'(got)/256.0);
      errors++;
    end
    else
      $display("  [ ok ] %-30s %0d (%0.4f)", what, got, real'(got)/256.0);
  endtask

  task automatic tick; @( negedge clk ); endtask

  initial begin
`ifndef NO_SHM
    $shm_open("waves.shm");
    $shm_probe("AS");
`endif

    rst = 1; pe_accept_w_in = 0; pe_valid_in = 0; pe_switch_in = 0;
    pe_enabled = 1; pe_psum_in = '0; pe_weight_in = '0; pe_input_in = '0;
    repeat (2) @( negedge clk );
    rst = 0;

    $display("");
    $display("=== 1. reset leaves every output defined ===");
    expect_q( "pe_psum_out",   pe_psum_out,   '0 );
    expect_q( "pe_input_out",  pe_input_out,  '0 );
    expect_q( "pe_weight_out", pe_weight_out, '0 );
    if ( pe_valid_out  !== 1'b0 ) begin $display("  [FAIL] pe_valid_out not 0");  errors++; end
    if ( pe_switch_out !== 1'b0 ) begin $display("  [FAIL] pe_switch_out not 0"); errors++; end

    $display("");
    $display("=== 2. load weight 3.0, switch it in, 2.0 * 3.0 + 1.0 = 7.0 ===");
    pe_accept_w_in = 1; pe_weight_in = 3*ONE;  tick;
    pe_accept_w_in = 0; pe_switch_in = 1;      tick;
    pe_switch_in = 0;
    pe_valid_in = 1; pe_input_in = 2*ONE; pe_psum_in = ONE; tick;
    tick;
    expect_q( "pe_psum_out", pe_psum_out, 7*ONE );

    $display("");
    $display("=== 3. load 5.0 without switching, answer must still be 7.0 ===");
    pe_accept_w_in = 1; pe_weight_in = 5*ONE;  tick;
    pe_accept_w_in = 0;
    pe_valid_in = 1; pe_input_in = 2*ONE; pe_psum_in = ONE; tick;
    tick;
    expect_q( "pe_psum_out", pe_psum_out, 7*ONE );

    $display("");
    $display("=== 4. now switch, 2.0 * 5.0 + 1.0 = 11.0 ===");
    pe_switch_in = 1;
    pe_valid_in = 1; pe_input_in = 2*ONE; pe_psum_in = ONE; tick;
    pe_switch_in = 0; tick;
    expect_q( "pe_psum_out", pe_psum_out, 11*ONE );

    $display("");
    if ( errors == 0 )
      $display(" SMOKE TEST PASSED, 0 errors");
    else
      $display(" SMOKE TEST FAILED, %0d errors", errors);
    $display("");
    $finish;
  end

  initial begin
    #10000;
    $display("[FAIL] timeout");
    $finish;
  end

endmodule
