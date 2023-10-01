module ysyx_23060061_Decoder (
  input [6:0] opcode,
  input [2:0] funct3,
  output RegWrite
);
  ysyx_23060061_MuxKeyWithDefault #(1, 10, 1) decoder(.out({RegWrite}), .key({opcode, funct3}), .default_out({1'b0}), .lut({
    {7'b0010011,3'b000}, {1'b1}
  }));
endmodule
