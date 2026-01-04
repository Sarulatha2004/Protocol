`timescale 1ns/1ps

module apb_spi_top #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)(
    // APB interface
    input  wire                  PCLK,
    input  wire                  PRESETn,
    input  wire                  PSEL,
    input  wire                  PENABLE,
    input  wire                  PWRITE,
    input  wire [ADDR_WIDTH-1:0] PADDR,
    input  wire [DATA_WIDTH-1:0] PWDATA,
    output wire [DATA_WIDTH-1:0] PRDATA,
    output wire                  PREADY,
    output wire                  PSLVERR,

    // SPI interface
    output wire spi_cs_n,
    output wire spi_sclk,
    output wire spi_mosi,
    input  wire spi_miso
);

    wire spi_wr_valid, spi_rd_valid, spi_ready;
    wire [DATA_WIDTH-1:0] spi_wr_data, spi_rd_data;
    wire [3:0] spi_wr_strb;
    wire [ADDR_WIDTH-1:0] spi_addr;
    wire spi_wr_done, spi_rd_done;
    wire [1:0] spi_resp;

    // APB → SPI Bridge
    apb_to_spi_bridge u_bridge (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR),

        .spi_addr(spi_addr),
        .spi_wr_data(spi_wr_data),
        .spi_wr_strb(spi_wr_strb),
        .spi_wr_valid(spi_wr_valid),
        .spi_rd_valid(spi_rd_valid),
        .spi_ready(spi_ready),

        .spi_rd_data(spi_rd_data),
        .spi_wr_done(spi_wr_done),
        .spi_rd_done(spi_rd_done),
        .spi_resp(spi_resp)
    );

    // SPI Master (UNCHANGED)
    spi_master u_spi_master (
        .clk(PCLK),
        .rst_n(PRESETn),

        .cmd_addr(spi_addr),
        .cmd_wr_data(spi_wr_data),
        .cmd_wr_strb(spi_wr_strb),
        .cmd_wr_valid(spi_wr_valid),
        .cmd_rd_valid(spi_rd_valid),
        .cmd_ready(spi_ready),

        .resp_rd_data(spi_rd_data),
        .resp_rd_done(spi_rd_done),
        .resp_wr_done(spi_wr_done),
        .resp_status(spi_resp),

        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso)
    );

    // SPI Slave (UNCHANGED)
    spi_slave u_spi_slave (
        .sclk(spi_sclk),
        .cs_n(spi_cs_n),
        .mosi(spi_mosi),
        .miso(spi_miso)
    );

endmodule

