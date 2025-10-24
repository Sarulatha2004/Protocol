module i2c_tb;
reg clk;
reg reset;
wire i2c_sda;
wire i2c_scl;


i2c_master2 uut ( .clk(clk), .reset(reset), .i2c_sda(i2c_sda), .i2c_scl(i2c_scl));

initial begin
        clk =0;
        forever begin
                clk = #1  ~clk;
        end
end


initial begin

        $dumpfile("i2c.vcd");
        $dumpvars;
        reset =1;

        #10;
        reset =0 ;

        #200;
        $finish;
end
endmodule
