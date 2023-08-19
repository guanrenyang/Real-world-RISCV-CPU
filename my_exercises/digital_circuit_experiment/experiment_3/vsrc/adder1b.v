module adder1b(a_i, b_i, c_i, s_i, c_iplus1);
    input a_i;
    input b_i;
    input c_i;
    output s_i;
    output c_iplus1;

    wire a_xor_b; 
    wire a_and_b;
    assign a_xor_b = a_i ^ b_i;
    assign a_and_b = a_i & b_i;
    assign s_i = a_xor_b ^ c_i ;
    assign c_iplus1 = a_and_b | (a_xor_b & c_i);

endmodule
