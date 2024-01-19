module ysyx_23060061_RandomDelayGenerator (
	input clk,
	input rst,
	output delay_trigger
);

	wire [`ysyx_23060061_RANDOM_NUMBER_BIT-1:0] random_number;
	ysyx_23060061_lfsr_random_generator #(`ysyx_23060061_RANDOM_NUMBER_BIT) lfsr_random_generator (
		.clk(clk),
		.reset(rst),
		.random_number(random_number)
	);

	reg [31:0] delay;
	reg [31:0] delay_counter;
	always @(posedge clk) begin
		if (~rst) begin
			delay <= {{(32-`ysyx_23060061_RANDOM_NUMBER_BIT){1'b0}}, random_number};
			delay_counter <= 0;
		end else begin
			if (delay_counter == delay) begin
				delay <= {{(32-`ysyx_23060061_RANDOM_NUMBER_BIT){1'b0}}, random_number};
				delay_counter <= 0;
			end else begin
				delay <= delay;
				delay_counter <= delay_counter + 1;
			end
		end
	end

	assign delay_trigger = (delay_counter == delay);
endmodule

module ysyx_23060061_lfsr_random_generator #(NR_BIT=32)(
    input clk,
    input reset, // active low
    output [NR_BIT-1:0] random_number
);

reg [NR_BIT-1:0] lfsr_reg;

// 定义反馈多项式
wire feedback = lfsr_reg[NR_BIT-1] ^ lfsr_reg[NR_BIT-2]; // 示例：x^8 + x^7 + 1

assign random_number = lfsr_reg;

always @(posedge clk ) begin
    if (~reset) begin
        lfsr_reg <= {NR_BIT{1'b1}}; // 非全零初始值
    end else begin
        lfsr_reg <= {lfsr_reg[NR_BIT-2:0], feedback};
    end
end

endmodule