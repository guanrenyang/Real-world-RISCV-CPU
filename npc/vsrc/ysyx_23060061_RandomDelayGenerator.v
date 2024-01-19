module ysyx_23060061_RandomDelayGenerator (
	input clk,
	input rst,
	output delay_trigger
);
	localparam [31:0] DELAY = 30;
	reg [31:0] delay;
	reg [31:0] delay_counter;
	always @(posedge clk) begin
		if (~rst) begin
			delay <= $random;
			delay_counter <= 0;
		end else begin
			if (delay_counter == delay) begin
				delay <= DELAY;
				delay_counter <= 0;
			end else begin
				delay <= delay;
				delay_counter <= delay_counter + 1;
			end
		end
	end

	assign delay_trigger = (delay_counter == delay);
endmodule