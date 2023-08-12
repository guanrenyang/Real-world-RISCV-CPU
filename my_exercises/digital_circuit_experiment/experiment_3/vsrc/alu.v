module alu (A, B, opcode, Result, Zero, Overflow);
    input [3: 0] A;
    input [3: 0] B;
    input [2: 0] opcode;
    output reg [3: 0] Result;
    output Zero;
    output Overflow;     

    wire [3: 0] sum;
    wire Sub;
    wire Carry;
    assign Sub = ((opcode == 3'b001) || (opcode == 3'b110) || (opcode == 3'b111)) ? 1'b1 : 1'b0;
    always @(*) begin
        case (opcode)
            3'b000: Result = sum;
            3'b001: Result = sum;
            3'b010: Result = 4'b1111 ^ A;
            3'b011: Result = (A & B);
            3'b100: Result = (A | B);
            3'b101: Result = (A ^ B);
            3'b110: Result = {1'b0, 1'b0, 1'b0, sum[3] ^ Overflow};
            3'b111: Result = {1'b0, 1'b0, 1'b0, Zero};
            default: Result = 4'b0000; 
        endcase;
    end

    adder4b adder(
        .A1(A),
        .B1(B),
        .Cin(Sub),
        .Zero(Zero),
        .Carry(Carry),
        .Overflow(Overflow),
        .Result(sum)
    );
endmodule