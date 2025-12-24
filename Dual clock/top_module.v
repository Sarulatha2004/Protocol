module apb_spi_top (
    input  wire       PCLK,
    input  wire       SCLK,
    input  wire       PRESETn,
    input  wire       PSEL,
    input  wire       PENABLE,
    input  wire       PWRITE,
    input  wire [7:0] PADDR,
    input  wire [7:0] PWDATA,
    output wire       MOSI,
    output wire       SS
);

wire fifo_wr_en;
wire [7:0] fifo_wr_data;
wire fifo_full, fifo_empty;
wire fifo_rd_en;
wire [7:0] fifo_rd_data;

apb_slave u_apb (
    .PCLK(PCLK),
    .PRESETn(PRESETn),
    .PSEL(PSEL),
    .PENABLE(PENABLE),
    .PWRITE(PWRITE),
    .PADDR(PADDR),
    .PWDATA(PWDATA),
    .fifo_full(fifo_full),
    .fifo_wr_en(fifo_wr_en),
    .fifo_wr_data(fifo_wr_data)
);

async_fifo u_fifo (
    .wr_clk(PCLK),
    .rd_clk(SCLK),
    .rst_n(PRESETn),
    .wr_en(fifo_wr_en),
    .wr_data(fifo_wr_data),
    .full(fifo_full),
    .rd_en(fifo_rd_en),
    .rd_data(fifo_rd_data),
    .empty(fifo_empty)
);

spi_master u_spi (
    .SCLK(SCLK),
    .rst_n(PRESETn),
    .fifo_empty(fifo_empty),
    .fifo_data(fifo_rd_data),
    .fifo_rd_en(fifo_rd_en),
    .MOSI(MOSI),
    .SS(SS)
);

endmodule
