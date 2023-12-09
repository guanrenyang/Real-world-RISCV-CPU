module ysyx_23060061_CSRs #(DATA_WIDTH = 1) (
  input clk,
  input rst,

  input csrEn, // csrEn==1'b0 when ecall and mret
  input [11:0] csrId,
  input [DATA_WIDTH-1:0] wdata,
  output [DATA_WIDTH-1:0] rdata,
  
  input ecall,
  input [31:0] pc,
  output [31:0] mtvec,
  output [31:0] mepc
);
  
  parameter INTERNAL_ADDR_WIDTH = 2;
  wire [INTERNAL_ADDR_WIDTH-1:0] csrId_internal;
  ysyx_23060061_MuxKey #(4, 12, 2) id_global_to_internal(
	.out(csrId_internal),
	.key(csrId),
	.lut({
		12'h300, 2'b00, // mstatus
		12'h305, 2'b01, // mtvec
		12'h341, 2'b10, // mepc
		12'h342, 2'b11  // mcause
	  })
  );

  reg [DATA_WIDTH-1:0] rf [(2**INTERNAL_ADDR_WIDTH)-1:0];

  integer i;
  always @(posedge clk) begin 
    if (rst) begin
      for (i = 0; i < (2**INTERNAL_ADDR_WIDTH); i = i + 1) begin
        rf[i] <= 0;  // Set each csr to zero
      end
    end
  end


  always @(posedge clk) begin
    if (ecall) begin
      rf[2'b10] <= pc;
      rf[2'b11] <= 32'h00000008;
    end
  end

  always @(posedge clk) begin
    if (csrEn) rf[csrId_internal] <= wdata;
  end
  
  assign rdata = rf[csrId_internal];
  assign mtvec = rf[2'b01];
  assign mepc = rf[2'b10];
endmodule
