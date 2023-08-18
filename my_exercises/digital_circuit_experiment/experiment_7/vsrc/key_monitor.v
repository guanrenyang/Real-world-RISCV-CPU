// `timescale 1ns / 1ps
module key_monitor(
  input clk,
  input clrn,
  input kbd_clk,
  input kbd_data,
  output [6:0] keycode_low,  
  output [6:0] keycode_high,
  output [6:0] ascii_low,
  output [6:0] ascii_high,
  output [6:0] count_low,
  output [6:0] count_high
);

parameter [1:0] STALL = 0, DISPLAY = 1, WAIT_CLOCK = 2;
parameter [7:0] STOP = 8'hF0;

reg [1:0] state;
wire [1:0] next_state;
reg [7:0] count;

reg [7:0] data;

wire [7:0] ps2_data; 
wire ready;
reg nextdata_n;
wire overflow; // disregrad overflow

wire [7:0] ascii_out;

initial begin
  state = STALL;
  count = 8'h00;
end

assign nextdata_n = ~ready;

always @(posedge clk) begin
  state <= next_state;
  if(ready) begin
    data <= ps2_data;
    if(ps2_data==STOP)
      count <= count + 1;
  end
end 

MuxKeyWithDefault#(3, 2, 2) stateMux(.out(next_state), .key(state), .default_out(STALL), .lut({
  STALL, ready ? DISPLAY : STALL,
  DISPLAY, (ready && ps2_data==STOP) ? WAIT_CLOCK : DISPLAY,
  WAIT_CLOCK, ready ? STALL : WAIT_CLOCK
  })); 

ps2_keyboard inst(
  .clk(clk),
  .clrn(clrn),
  .ps2_clk(kbd_clk),
  .ps2_data(kbd_data),
  .data(ps2_data),
  .ready(ready),
  .nextdata_n(nextdata_n),
  .overflow(overflow)
);

bcd7seg display_keycode_low(.en(state==DISPLAY), .b(data[3:0]), .h(keycode_low));
bcd7seg display_keycode_high(.en(state==DISPLAY), .b(data[7:4]), .h(keycode_high));
bcd7seg display_ascii_low(.en(state==DISPLAY), .b(ascii_out[3:0]), .h(ascii_low));
bcd7seg display_ascii_high(.en(state==DISPLAY), .b(ascii_out[7:4]), .h(ascii_high));
bcd7seg display_count_low(.en(1'b1), .b(count[3:0]), .h(count_low));
bcd7seg display_count_high(.en(1'b1), .b(count[7:4]), .h(count_high));

MuxKeyWithDefault#(5, 8, 8) keycode2ascii(.out(ascii_out), .key(data), .default_out({4'd4, 4'd2}), .lut({
  8'h16, {4'd4, 4'd9},
  8'h1e, {4'd5, 4'd0},
  8'h26, {4'd5, 4'd1},
  8'h25, {4'd5, 4'd2},
  8'h2e, {4'd5, 4'd3}
})); 
// For testing
always @(clk) begin 
  $display("clk: %d, state: %d, next_state: %d, ps2_data: %h, ready: %d", clk, state, next_state, data, ready);
end

endmodule
