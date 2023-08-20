module encode83(x, en, y, sign, hex0);
    input [7:0] x;
    input en;
    output reg [2:0] y;
    output reg sign;
    output [6:0] hex0;
    integer i;
    always @(x or en) begin
        if (en) begin
            y = 0;
            sign = 0;
            for (i = 0; i<=7; i = i + 1) begin
                if(x[i] == 1) begin
                    y = i[2:0];
                    sign = 1;
                end
            end
        end
        else begin
            y = 0;
            sign = 0;
        end
    end

    bcd7seg HEX0(
        {1'b0, y},
        hex0
    );
endmodule