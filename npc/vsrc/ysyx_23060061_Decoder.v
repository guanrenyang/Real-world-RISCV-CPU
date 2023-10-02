module ysyx_23060061_Decoder (
  input [6:0] opcode,
  input [2:0] funct3,
  output RegWrite,
  output ebreak
);
  ysyx_23060061_MuxKeyWithDefault #(2, 10, 2) decoder(.out({RegWrite, ebreak}), .key({opcode, funct3}), .default_out({2'b00}), .lut({
    {7'b0010011, 3'b000}, {2'b10},
    {7'b1110011, 3'b000}, {2'b01}
  }));
endmodule
