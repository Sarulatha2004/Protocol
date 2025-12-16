module apb_top(
	input pclk,
	input presetn,
	input r_w,
	input transfer,
	input [7:0]write_paddr,
	input [7:0]write_data,
	input [7:0]read_paddr,
	output ready,
	output [7:0]prdata
);

wire psel,penable,pwrite;
wire [7:0]paddr,pwrite_data,read_data_out;

apb_master uut(
	.pclk(pclk),
	.presetn(presetn),
	.r_w(r_w),
	.transfer(transfer),
	.write_paddr,
	.write_data(write_data),
	.read_paddr(read_paddr),
	.ready(ready),
	.prdata(prdata),
	.psel(psel),
	.penable(penable),
	.pwrite(pwrite),
	.paddr(paddr),
	.pwrite_data(pwrite_data),
	.read_data_out(read_data_out)
);

apb_slave uut1(
	.pclk(pclk),
        .presetn(presetn),
	.pwrite(pwrite),
	.psel(psel),
	.penable(penable),
	.paddr(paddr),
	.pwrite_data(pwrite_data),
	.prdata(prdata),
	.ready(ready)
);


endmodule
