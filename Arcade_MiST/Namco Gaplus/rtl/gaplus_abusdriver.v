
module gaplus_busdriver
(
    input iENABLE,
    input iSELECT,

    input [31:0] iBUS0,
    input [31:0] iBUS1,

    output [31:0] oBUS

);

assign oBUS = iENABLE ? ( iSELECT ? iBUS0 : iBUS1 ) : 0;

endmodule


module dataselector2
(
	output [7:0] oDATA,

	input iSEL0,
	input [7:0] iDATA0,

	input iSEL1,
	input [7:0] iDATA1,

	input [7:0] dData
);

assign oDATA = iSEL0 ? iDATA0 :
					iSEL1 ? iDATA1 :
					dData;

endmodule

module dataselector4
(
	output [7:0] oDATA,

	input iSEL0,
	input [7:0] iDATA0,

	input iSEL1,
	input [7:0] iDATA1,

	input iSEL2,
	input [7:0] iDATA2,

	input iSEL3,
	input [7:0] iDATA3,

	input [7:0] dData
);

assign oDATA = iSEL0 ? iDATA0 :
					iSEL1 ? iDATA1 :
					iSEL2 ? iDATA2 :
					iSEL3 ? iDATA3 :
					dData;

endmodule


