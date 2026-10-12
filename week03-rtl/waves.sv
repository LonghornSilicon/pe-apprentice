module waves;
  initial begin
    $dumpfile("waves.vcd");
    $dumpvars(0, pe_smoke_tb);
  end
endmodule
