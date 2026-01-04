`timescale 1ns/1ps

module apb_to_spi_bridge (
    input  wire        PCLK,
    input  wire        PRESETn,
    input  wire        PSEL,
    input  wire        PENABLE,
    input  wire        PWRITE,
    input  wire [31:0] PADDR,
    input  wire [31:0] PWDATA,
    output reg  [31:0] PRDATA,
    output reg         PREADY,
    output reg         PSLVERR,

    output reg  [31:0] spi_addr,
    output reg  [31:0] spi_wr_data,
    output reg  [3:0]  spi_wr_strb,
    output reg         spi_wr_valid,
    output reg         spi_rd_valid,
    input  wire        spi_ready,

    input  wire [31:0] spi_rd_data,
    input  wire        spi_wr_done,
    input  wire        spi_rd_done,
    input  wire [1:0]  spi_resp
);

    localparam IDLE = 2'd0,
               SETUP = 2'd1,
               ACCESS = 2'd2;

    reg [1:0] state;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            state <= IDLE;
            PREADY <= 0;
            PSLVERR <= 0;
            spi_wr_valid <= 0;
            spi_rd_valid <= 0;
        end else begin
            PREADY <= 0;
            spi_wr_valid <= 0;
            spi_rd_valid <= 0;

            case (state)
                IDLE: begin
                    if (PSEL && !PENABLE)
                        state <= SETUP;
                end

                SETUP: begin
                    spi_addr <= PADDR;
                    spi_wr_data <= PWDATA;
                    spi_wr_strb <= 4'b1111;
                    state <= ACCESS;
                end

                ACCESS: begin
                    if (spi_ready) begin
                        if (PWRITE)
                            spi_wr_valid <= 1;
                        else
                            spi_rd_valid <= 1;

                        state <= IDLE;
                    end
                end
            endcase

            if (spi_rd_done)
                PRDATA <= spi_rd_data;

            if (spi_wr_done || spi_rd_done)
                PREADY <= 1;
        end
    end
endmodule

