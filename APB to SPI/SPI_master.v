`timescale 1ns/1ps

// ============================================================================
// SPI MASTER - Communicates with external SPI slave
// ============================================================================
module spi_master #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter SPI_CLK_DIV = 4,
    parameter NUM_REGS = 256
)(
    input  wire                   clk,
    input  wire                   rst_n,

    // Command Interface
    input  wire [ADDR_WIDTH-1:0]  cmd_addr,
    input  wire [DATA_WIDTH-1:0]  cmd_wr_data,
    input  wire [3:0]             cmd_wr_strb,
    input  wire                   cmd_wr_valid,
    input  wire                   cmd_rd_valid,
    output reg                    cmd_ready,

    // Response Interface
    output reg  [DATA_WIDTH-1:0]  resp_rd_data,
    output reg                    resp_rd_done,
    output reg                    resp_wr_done,
    output reg  [1:0]             resp_status,

    // SPI Physical Interface
    output reg                    spi_sclk,
    output reg                    spi_cs_n,
    output reg                    spi_mosi,
    input  wire                   spi_miso
);

    // SPI Commands
    localparam CMD_WRITE = 8'h02;
    localparam CMD_READ  = 8'h03;
    localparam RESP_OKAY = 2'b00;

    // FSM States
    localparam IDLE     = 3'd0;
    localparam START    = 3'd1;
    localparam SEND_CMD = 3'd2;
    localparam SEND_ADDR = 3'd3;
    localparam SEND_STRB = 3'd4;
    localparam SEND_DATA = 3'd5;
    localparam RECV_DATA = 3'd6;
    localparam FINISH   = 3'd7;

    reg [2:0]  state;
    reg [7:0]  bit_count;
    reg [7:0]  spi_cmd;
    reg [ADDR_WIDTH-1:0] spi_addr;
    reg [3:0]  spi_strb;
    reg [DATA_WIDTH-1:0] spi_data;
    reg        is_write;

    // SPI clock generation - toggle every SPI_CLK_DIV/2 clocks
    reg [7:0] clk_div_count;
    wire clk_div_pulse = (clk_div_count == (SPI_CLK_DIV/2 - 1));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div_count <= 0;
        end else begin
            if (state == IDLE || state == START || state == FINISH) begin
                clk_div_count <= 0;
            end else if (clk_div_pulse) begin
                clk_div_count <= 0;
            end else begin
                clk_div_count <= clk_div_count + 1;
            end
        end
    end

    // Main FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            spi_sclk <= 0;
            spi_cs_n <= 1;
            spi_mosi <= 0;
            cmd_ready <= 1;
            resp_rd_data <= 0;
            resp_rd_done <= 0;
            resp_wr_done <= 0;
            resp_status <= RESP_OKAY;
            bit_count <= 0;
        end else begin
            resp_rd_done <= 0;
            resp_wr_done <= 0;

            case (state)
                IDLE: begin
                    spi_cs_n <= 1;
                    spi_sclk <= 0;
                    cmd_ready <= 1;
                    bit_count <= 0;
                    
                    if (cmd_wr_valid || cmd_rd_valid) begin
                        spi_cmd <= cmd_wr_valid ? CMD_WRITE : CMD_READ;
                        spi_addr <= cmd_addr;
                        spi_strb <= cmd_wr_strb;
                        spi_data <= cmd_wr_data;
                        is_write <= cmd_wr_valid;
                        cmd_ready <= 0;
                        state <= START;
                    end
                end

                START: begin
                    spi_cs_n <= 0;  // Assert CS
                    state <= SEND_CMD;
                    bit_count <= 0;
                end

                SEND_CMD: begin
                    if (clk_div_pulse) begin
                        if (!spi_sclk) begin
                            // Falling edge - update MOSI
                            spi_mosi <= spi_cmd[7 - bit_count];
                            spi_sclk <= 1;
                        end else begin
                            // Rising edge - slave samples
                            spi_sclk <= 0;
                            if (bit_count == 7) begin
                                state <= SEND_ADDR;
                                bit_count <= 0;
                            end else begin
                                bit_count <= bit_count + 1;
                            end
                        end
                    end
                end

                SEND_ADDR: begin
                    if (clk_div_pulse) begin
                        if (!spi_sclk) begin
                            spi_mosi <= spi_addr[ADDR_WIDTH-1 - bit_count];
                            spi_sclk <= 1;
                        end else begin
                            spi_sclk <= 0;
                            if (bit_count == ADDR_WIDTH-1) begin
                                bit_count <= 0;
                                if (is_write)
                                    state <= SEND_STRB;
                                else
                                    state <= RECV_DATA;
                            end else begin
                                bit_count <= bit_count + 1;
                            end
                        end
                    end
                end

                SEND_STRB: begin
                    if (clk_div_pulse) begin
                        if (!spi_sclk) begin
                            spi_mosi <= spi_strb[3 - bit_count];
                            spi_sclk <= 1;
                        end else begin
                            spi_sclk <= 0;
                            if (bit_count == 3) begin
                                state <= SEND_DATA;
                                bit_count <= 0;
                            end else begin
                                bit_count <= bit_count + 1;
                            end
                        end
                    end
                end

                SEND_DATA: begin
                    if (clk_div_pulse) begin
                        if (!spi_sclk) begin
                            spi_mosi <= spi_data[DATA_WIDTH-1 - bit_count];
                            spi_sclk <= 1;
                        end else begin
                            spi_sclk <= 0;
                            if (bit_count == DATA_WIDTH-1) begin
                                state <= FINISH;
                            end else begin
                                bit_count <= bit_count + 1;
                            end
                        end
                    end
                end

                RECV_DATA: begin
                    if (clk_div_pulse) begin
                        if (!spi_sclk) begin
                            // Rising edge - SCLK goes high, slave will update MISO
                            spi_sclk <= 1;
                            // Sample MISO here (it was updated on previous falling edge)
                            if (bit_count > 0) begin  // Don't sample on first bit
                                resp_rd_data <= {resp_rd_data[DATA_WIDTH-2:0], spi_miso};
                            end
                        end else begin
                            // Falling edge - SCLK goes low
                            spi_sclk <= 0;
                            if (bit_count == 0) begin
                                // First bit - sample now after slave has set it
                                resp_rd_data <= {resp_rd_data[DATA_WIDTH-2:0], spi_miso};
                            end
                            
                            if (bit_count == DATA_WIDTH-1) begin
                                state <= FINISH;
                            end else begin
                                bit_count <= bit_count + 1;
                            end
                        end
                    end
                end

                FINISH: begin
                    spi_cs_n <= 1;  // Deassert CS
                    spi_sclk <= 0;
                    resp_status <= RESP_OKAY;
                    
                    if (is_write) begin
                        resp_wr_done <= 1;
                    end else begin
                        resp_rd_done <= 1;
                    end
                    
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
