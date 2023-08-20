module adder4b(A1, B1, Cin, Carry, Zero, Overflow, Result);
    input [3: 0] A1;
    input [3: 0] B1;
    input Cin;
    output Zero;
    output Carry;
    output Overflow;
    output [3: 0] Result;

    wire [3:0] C1;
    wire [3:0] t_no_Cin;
    // wire [3:0] sum;
    assign t_no_Cin = {4{Cin}} ^ B1; // For substraction
    assign Carry = C1[3];
    assign Zero = ~(|Result);
    assign Overflow = (A1[3] == t_no_Cin[3]) && (Result[3] != A1[3]);

    adder1b adder0(
        .a_i(A1[0]),
        .b_i(t_no_Cin[0]),
        .c_i(Cin),
        .s_i(Result[0]),
        .c_iplus1(C1[0])
    );
    adder1b adder1(
        .a_i(A1[1]),
        .b_i(t_no_Cin[1]),
        .c_i(C1[0]),
        .s_i(Result[1]),
        .c_iplus1(C1[1])
    );
    adder1b adder2(
        .a_i(A1[2]),
        .b_i(t_no_Cin[2]),
        .c_i(C1[1]),
        .s_i(Result[2]),
        .c_iplus1(C1[2])
    );
    adder1b adder3(
        .a_i(A1[3]),
        .b_i(t_no_Cin[3]),
        .c_i(C1[2]),
        .s_i(Result[3]),
        .c_iplus1(C1[3])
    );

   
endmodule
