module ysyx_23060061_RegisterFile #(ADDR_WIDTH = 1, DATA_WIDTH = 1) (
  input clk,
  input rst,

  input [DATA_WIDTH-1:0] wdata,
  input [ADDR_WIDTH-1:0] waddr,
  input wen,

  input [ADDR_WIDTH-1:0] raddr1,
  input [ADDR_WIDTH-1:0] raddr2,
  output [DATA_WIDTH-1:0] rdata1,
  output [DATA_WIDTH-1:0] rdata2
);
  reg [DATA_WIDTH-1:0] rf [(2**ADDR_WIDTH)-1:0];

  integer i;
  always @(posedge clk) begin 
    if (rst) begin
      for (i = 0; i < (2**ADDR_WIDTH); i = i + 1) begin
        rf[i] <= 0;  // Set each register to zero
      end
    end
  end

  always @(posedge clk) begin
    if (wen && (waddr!=0)) rf[waddr] <= wdata;
  end
  
  assign rdata1 = rf[raddr1];
  assign rdata2 = rf[raddr2];

endmodule
