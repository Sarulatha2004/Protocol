module tb_apb_spi;

reg PCLK = 0;
reg SCLK = 0;
reg PRESETn = 0;
reg PSEL, PENABLE, PWRITE;
reg [7:0] PADDR, PWDATA;
wire MOSI, SS;

always #5 PCLK = ~PCLK;
always #3 SCLK = ~SCLK;

apb_spi_top dut (
    .PCLK(PCLK),
    .SCLK(SCLK),
    .PRESETn(PRESETn),
    .PSEL(PSEL),
    .PENABLE(PENABLE),
    .PWRITE(PWRITE),
    .PADDR(PADDR),
    .PWDATA(PWDATA),
    .MOSI(MOSI),
    .SS(SS)
);

initial begin
  $dumpfile("Dual_clock.vcd");
  $dumpvars;
    PRESETn = 0;
    PSEL = 0; PENABLE = 0; PWRITE = 0;
    #20 PRESETn = 1;

    apb_write(8'hA5);
    apb_write(8'h3C);
    apb_write(8'hF0);

    #1000;
    $finish;
    end

    task apb_write(input [7:0] data);
	    begin
		    @(posedge PCLK);

		    PSEL=1;PWRITE=1;PADDR=8'h00;PWDATA=data;

		    @(posedge PCLK);
		    PENABLE=1;

		    @(posedge PCLK);
		    PSEL=0;PENABLE=0;
	    end
    endtask
endmodule
