module apb_slave(
	input pclk,
	input presetn,
	input pwrite,
	input psel,
	input penable,
	input [7:0]paddr,
	input [7:0]pwrite_data,
	output reg[7:0] prdata,
        output reg ready
);

reg [7:0]mem[255:0];

always @ (posedge pclk or negedge presetn)
begin
	if(!presetn)
	begin
		ready <=1'b0;
		prdata<=8'b0;
	end
	else
	begin
		if(penable)begin
			ready <=1'b1;
			if(pwrite)
				mem[paddr]<=pwrite_data;
			else
				prdata<=mem[paddr];
		end
		else
			ready <= 1'b0;
	end
end
endmodule

