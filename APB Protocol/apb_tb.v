module apb_tb;
reg pclk;
reg presetn;
reg transfer;
reg r_w;
reg [7:0]write_paddr;
reg [7:0]read_paddr;
reg [7:0]write_data;
wire ready;
wire [7:0]prdata;

apb_top uut(
	.pclk(pclk),
	.presetn(presetn),
	.r_w(r_w),
	.transfer(transfer),
	.write_paddr(write_paddr),
        .read_paddr(read_paddr),
        .write_data(write_data),
        .ready(ready),
        .prdata(prdata)
);

always #5 pclk=~pclk;

initial begin

        $dumpfile("APB.vcd");
        $dumpvars;

        pclk=0;
        presetn=0;
        r_w=0;
        transfer=0;
        write_paddr=8'd0;
        read_paddr=8'd0;
        write_data=8'd0;

        #10;

        presetn=1;

        #10;

        //Write the data

        transfer=1;
        r_w=1;
	#5;
        write_paddr=8'h45;
        write_data=8'h67;

        #30;


        transfer=0;

        #30;

        transfer=1;
        r_w=0;
        read_paddr=8'h45;
        
	#20;

	transfer=0;

	#30;
	$finish;

end
endmodule
