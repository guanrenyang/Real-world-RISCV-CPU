module ysyx_23060061_BranchComp (
	input [31:0] rdata1,
	input [31:0] rdata2,
	input BrUn, // branch unsigned
	output BrEq,
	output BrLt
);
	wire SignedBrEq;
	wire SignedBrLt;
	assign SignedBrEq = $signed(rdata1) == $signed(rdata2);
	assign SignedBrLt = $signed(rdata1) < $signed(rdata2);	

	wire UnsignedBrEq;
	wire UnsignedBrLt;
	assign UnsignedBrEq = rdata1 == rdata2;
	assign UnsignedBrLt = rdata1 < rdata2;
	
	assign BrEq = BrUn ? UnsignedBrEq : SignedBrEq;
	assign BrLt = BrUn ? UnsignedBrLt : SignedBrLt;
endmodule