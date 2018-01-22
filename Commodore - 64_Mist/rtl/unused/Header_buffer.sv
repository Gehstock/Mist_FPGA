// 64 byte buffer for loading files
// used to interrogate file type
// L.C.Ashmore 17
//
//


module  header_buffer
(
inout reg [7:0] header_buff [0:63]
); 

integer i;

initial begin
 	for (i = 0; i < 64; i = i +1)
			header_buff [i] = 0;
	end
endmodule
	