//------------------------------------------------------------------------
// pe_array_tb.sv
//------------------------------------------------------------------------
// Self-checking test for pe_array: two matrix products back to back with a
// weight swap between them, Y1 = X1 * W1 then Y2 = X2 * W2. The second
// weight set is loaded while the first product is still streaming, which is
// the whole reason the PE has two weight registers.
//
// The array has no controller. This testbench is the controller: it skews
// row r by r cycles on the way in and de-skews column c by c cycles on the
// way out. CHALLENGE.md asks you to derive the two timing constraints the
// weight load has to meet; both are written out below as asserts.
//
//   +define+N=8      array size, default 8
//   xrun -sv ../rtl/fxp.sv ../rtl/pe.sv ../rtl/pe_array.sv ../rtl/pe_array_tb.sv

`timescale 1ns/1ps

module pe_array_tb;

`ifndef N
  `define N 8
`endif
  localparam int N  = `N;
  localparam int K  = 3*N;            // activation vectors per batch; see the two constraints below
  localparam int QI = 8, QF = 8, DW = 16;
  localparam int ONE = 256;

  logic clk = 0;
  always #5 clk = ~clk;
  logic rst, enabled, accept_w;
  logic [N*DW-1:0] a_in, w_in, psum_out;
  logic [N-1:0]    valid_in, switch_in, valid_out;

  pe_array #(.N(N), .QI(QI), .QF(QF)) dut (.*);

  //----------------------------------------------------------------------
  // Q8.8 arithmetic, bit for bit what rtl/fxp.sv does
  //----------------------------------------------------------------------
  function automatic logic signed [DW-1:0] q_mul(logic signed [DW-1:0] a, b);
    logic signed [2*DW-1:0] p = a * b;
    return p[DW+QF-1 : QF];
  endfunction

  function automatic logic signed [DW-1:0] q_add(logic signed [DW-1:0] a, b);
    logic signed [DW:0] s = a + b;
    if (s[DW] != s[DW-1])
      return s[DW] ? {1'b1, {(DW-1){1'b0}}} : {1'b0, {(DW-1){1'b1}}};
    return s[DW-1:0];
  endfunction

  //----------------------------------------------------------------------
  // Test data. Small values so nothing saturates; a few halves so the
  // multiplier's truncation is exercised.
  //----------------------------------------------------------------------
  logic signed [DW-1:0] X1 [0:K-1][0:N-1], X2 [0:K-1][0:N-1];
  logic signed [DW-1:0] W1 [0:N-1][0:N-1], W2 [0:N-1][0:N-1];
  logic signed [DW-1:0] Y1 [0:K-1][0:N-1], Y2 [0:K-1][0:N-1];

  function automatic logic signed [DW-1:0] small_q(int seed);
    // -3.0 .. +3.0 in steps of 0.5
    int v = (seed % 13) - 6;
    return v * (ONE / 2);
  endfunction

  task automatic fill;
    for (int k = 0; k < K; k++)
      for (int r = 0; r < N; r++) begin
        X1[k][r] = small_q(7*k + 3*r + 1);
        X2[k][r] = small_q(5*k + 11*r + 2);
      end
    for (int r = 0; r < N; r++)
      for (int c = 0; c < N; c++) begin
        W1[r][c] = small_q(3*r + 5*c + 4);
        W2[r][c] = small_q(9*r + 2*c + 6);
      end
    // The array adds top to bottom starting from zero. Match that order.
    for (int k = 0; k < K; k++)
      for (int c = 0; c < N; c++) begin
        Y1[k][c] = '0; Y2[k][c] = '0;
        for (int r = 0; r < N; r++) begin
          Y1[k][c] = q_add(Y1[k][c], q_mul(X1[k][r], W1[r][c]));
          Y2[k][c] = q_add(Y2[k][c], q_mul(X2[k][r], W2[r][c]));
        end
      end
  endtask

  //----------------------------------------------------------------------
  // Schedule, in driver steps. One step = one negedge; the PEs sample on
  // the following posedge.
  //
  //   load 1    steps 0 .. N-1          W1 shifts down every column
  //   batch 1   vector k, row r         step  S1 + k + r
  //   load 2    steps S1+L .. S1+L+N-1  W2 shifts down behind batch 1
  //   batch 2   vector k, row r         step  S2 + k + r,  S2 = S1 + K
  //
  // Result for vector k, column c of batch b appears on psum_out[c] at step
  // Sb + k + N + c; the east valid of row r at step Sb + k + N + r.
  //
  // PE(r,c) switches at step Sb + r + c and reads weight_bg on that cycle,
  // so the last PE of a batch, PE(N-1,N-1), switches at step Sb + 2N - 2.
  // accept_w is a broadcast: on every load cycle every PE captures whatever
  // its north neighbour's weight_out holds, so from the first load cycle to
  // the last, weight_bg is in flight in every PE. The second load must sit
  // entirely between the two switch wavefronts:
  //   starts after batch 1's last switch:  S1 + L + 1 > S1 + 2N - 2   =>  L >= 2N - 2
  //   lands before batch 2's first switch: S1 + L + N <= S2 = S1 + K   =>  K >= L + N
  // Together K >= 3N - 2: the price of a stall-free weight swap with a
  // shift-down load and a broadcast accept. CHALLENGE.md asks you to derive
  // these and to say what it would take to bring the price down to 2N - 1.
  //----------------------------------------------------------------------
  localparam int S1 = N;
  localparam int L  = 2*N - 2;
  localparam int S2 = S1 + K;
  localparam int LAST = S2 + (K-1) + N + (N-1);   // last result step

  initial begin
    if (!(L >= 2*N-2)) begin $display("[FAIL] load 2 would overwrite weights batch 1 still needs"); $finish; end
    if (!(L + N <= K)) begin $display("[FAIL] load 2 would not finish before batch 2 switches"); $finish; end
  end

  int errors = 0, checked = 0;

  task automatic drive(int step);
    a_in = '0; valid_in = '0; switch_in = '0; w_in = '0; accept_w = 0;
    if (step < 0) return;
    // weight loads: row N-1 first, so the last one presented lands in row 0
    if (step < N) begin
      accept_w = 1;
      for (int c = 0; c < N; c++) w_in[c*DW +: DW] = W1[N-1-step][c];
    end
    if (step >= S1+L && step < S1+L+N) begin
      accept_w = 1;
      for (int c = 0; c < N; c++) w_in[c*DW +: DW] = W2[N-1-(step-S1-L)][c];
    end
    // activations, skewed by row
    for (int r = 0; r < N; r++) begin
      int k1 = step - S1 - r;
      int k2 = step - S2 - r;
      if (k1 >= 0 && k1 < K) begin
        a_in[r*DW +: DW] = X1[k1][r]; valid_in[r] = 1; switch_in[r] = (k1 == 0);
      end
      else if (k2 >= 0 && k2 < K) begin
        a_in[r*DW +: DW] = X2[k2][r]; valid_in[r] = 1; switch_in[r] = (k2 == 0);
      end
    end
  endtask

  task automatic check(int step);
    for (int c = 0; c < N; c++) begin
      int k1 = step - S1 - N - c;
      int k2 = step - S2 - N - c;
      logic signed [DW-1:0] got = psum_out[c*DW +: DW];
      if (k1 >= 0 && k1 < K)      cmp($sformatf("Y1[%0d][%0d]", k1, c), got, Y1[k1][c]);
      else if (k2 >= 0 && k2 < K) cmp($sformatf("Y2[%0d][%0d]", k2, c), got, Y2[k2][c]);
    end
    for (int r = 0; r < N; r++) begin
      int k1 = step - S1 - N - r;
      int k2 = step - S2 - N - r;
      bit exp_v = (k1 >= 0 && k1 < K) || (k2 >= 0 && k2 < K);
      if (valid_out[r] !== exp_v) begin
        $display("  [FAIL] step %0d valid_out[%0d] expected %0b got %0b", step, r, exp_v, valid_out[r]);
        errors++;
      end
    end
  endtask

  task automatic cmp(string what, logic signed [DW-1:0] got, exp);
    checked++;
    if (got !== exp) begin
      $display("  [FAIL] %-12s expected %0d (%0.4f)  got %0d (%0.4f)",
               what, exp, real'(exp)/256.0, got, real'(got)/256.0);
      errors++;
    end
  endtask

  initial begin
`ifndef NO_SHM
    $shm_open("waves.shm");
    $shm_probe("AS");
`endif
    fill();
    rst = 1; enabled = 1; drive(-1);
    repeat (2) @(negedge clk);
    rst = 0;

    for (int step = 0; step <= LAST; step++) begin
      @(negedge clk);
      check(step);
      drive(step);
    end
    @(negedge clk);

    $display("");
    $display(" pe_array N=%0d: %0d results checked, %0d errors", N, checked, errors);
    if (errors == 0) $display(" ARRAY TEST PASSED");
    else             $display(" ARRAY TEST FAILED");
    $display("");
    $finish;
  end

  initial begin
    #100000;
    $display("[FAIL] timeout");
    $finish;
  end

endmodule
