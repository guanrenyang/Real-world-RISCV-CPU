module bcd7seg(
    input [3:0] b,
    output reg [6:0] h
);
    always @(*) begin
        case (b)
            4'd1: h = 7'b1111001;
            4'd2: h = 7'b0100100;
            4'd3: h = 7'b0110000;
            4'd4: h = 7'b0011001;
            4'd5: h = 7'b0010010;
            4'd6: h = 7'b0000010;
            4'd7: h = 7'b1111000;
            4'd8: h = 7'b0000000;
            4'd9: h = 7'b0010000;
            default: h = 7'b1111111; 
        endcase
    end
endmodule