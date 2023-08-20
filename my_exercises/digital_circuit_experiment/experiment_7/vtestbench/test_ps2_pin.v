module test_ps2_pin(ps2_clk, ps2_data);
  input ps2_clk;
  input ps2_data;

  always @(*) begin
    $display("clk: %d, data: %d", ps2_clk, ps2_data);
  end
endmodule
