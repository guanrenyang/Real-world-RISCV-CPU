module barrel_shifter(clk, hex0, hex1);
    input clk;
    output [6:0] hex0;
    output [6:0] hex1;
    
    reg [7:0] din;
    reg [7:0] dout;

    initial begin
        din = 8'b00000001;
        dout = 8'b00000000;
    end 

    always @(posedge clk) begin
        dout <= {din[4] ^ din[3] ^ din[2] ^ din[0], din[7:1]};
        din <= dout;
    end

    bcd7seg HEX0(.b(dout[3:0]), .h(hex0));
    bcd7seg HEX1(.b(dout[7:4]), .h(hex1));

endmodule
