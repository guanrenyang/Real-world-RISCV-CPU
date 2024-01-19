module ysyx_23060061_LSFR #(BIT=1) (
	input clk,
	input rst, // activate low
	input flush,
	input in,
	output out
);
	reg [BIT-1:0] regs;
	always @(posedge clk) begin
		if (~rst) begin
			regs <= 0;
		end else if (flush) begin
			regs <= 0;
		end else begin
			regs <= {regs[BIT-2:0], in};
		end
	end
	
	assign out = regs[BIT-1];
endmodule