`timescale 1ns/1ps

// ============================================================================
// SPI SLAVE - With internal memory
// ============================================================================
module spi_slave #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter NUM_REGS = 256
)(
    input  wire sclk,
    input  wire cs_n,
    input  wire mosi,
    output reg  miso
);

    localparam CMD_WRITE = 8'h02;
    localparam CMD_READ  = 8'h03;

    // Internal memory
    reg [DATA_WIDTH-1:0] memory [0:NUM_REGS-1];
    
    // State machine
    localparam IDLE      = 3'd0;
    localparam GET_CMD   = 3'd1;
    localparam GET_ADDR  = 3'd2;
    localparam GET_STRB  = 3'd3;
    localparam WRITE_DATA = 3'd4;
    localparam READ_DATA  = 3'd5;
    
    reg [2:0] state;
    reg [7:0] bit_count;
    reg [7:0] cmd;
    reg [ADDR_WIDTH-1:0] addr;
    reg [3:0] strb;
    reg [DATA_WIDTH-1:0] data;
    
    integer i;
    initial begin
        for(i=0; i<NUM_REGS; i=i+1) memory[i] = 32'h0;
    end

    wire [ADDR_WIDTH-1:0] mem_idx = addr >> 2;

    // Sample on rising edge of SCLK
    always @(posedge sclk or posedge cs_n) begin
        if (cs_n) begin
            state <= IDLE;
            bit_count <= 0;
            cmd <= 0;
            addr <= 0;
            strb <= 0;
            data <= 0;
        end else begin
            case (state)
                IDLE: begin
                    state <= GET_CMD;
                    bit_count <= 0;
                    cmd <= {cmd[6:0], mosi};
                end
                
                GET_CMD: begin
                    cmd <= {cmd[6:0], mosi};
                    if (bit_count == 6) begin  // 7 more bits (total 8)
                        state <= GET_ADDR;
                        bit_count <= 0;
                    end else begin
                        bit_count <= bit_count + 1;
                    end
                end
                
                GET_ADDR: begin
                    addr <= {addr[ADDR_WIDTH-2:0], mosi};
                    if (bit_count == ADDR_WIDTH-1) begin
                        bit_count <= 0;
                        // Address is now complete (including the current mosi bit)
                        if (cmd == CMD_WRITE) begin
                            state <= GET_STRB;
                        end else if (cmd == CMD_READ) begin
                            state <= READ_DATA;
                            // Load data using the COMPLETE address
                            if (({addr[ADDR_WIDTH-2:0], mosi} >> 2) < NUM_REGS)
                                data <= memory[({addr[ADDR_WIDTH-2:0], mosi} >> 2)];
                            else
                                data <= 32'h0;
                        end else begin
                            state <= IDLE;
                        end
                    end else begin
                        bit_count <= bit_count + 1;
                    end
                end
                
                GET_STRB: begin
                    strb <= {strb[2:0], mosi};
                    if (bit_count == 3) begin
                        state <= WRITE_DATA;
                        bit_count <= 0;
                    end else begin
                        bit_count <= bit_count + 1;
                    end
                end
                
                WRITE_DATA: begin
                    data <= {data[DATA_WIDTH-2:0], mosi};
                    if (bit_count == DATA_WIDTH-1) begin
                        // Write to memory with byte masking
                        if (mem_idx < NUM_REGS) begin
                            if (strb[0]) memory[mem_idx[7:0]][7:0]   <= {data[6:0], mosi};
                            if (strb[1]) memory[mem_idx[7:0]][15:8]  <= data[14:7];
                            if (strb[2]) memory[mem_idx[7:0]][23:16] <= data[22:15];
                            if (strb[3]) memory[mem_idx[7:0]][31:24] <= data[30:23];
                        end
                        state <= IDLE;
                    end else begin
                        bit_count <= bit_count + 1;
                    end
                end
                
                READ_DATA: begin
                    // Just count bits, MISO is driven separately
                    if (bit_count == DATA_WIDTH-1) begin
                        state <= IDLE;
                    end else begin
                        bit_count <= bit_count + 1;
                    end
                end
            endcase
        end
    end

    // Drive MISO on falling edge of SCLK
    always @(negedge sclk or posedge cs_n) begin
        if (cs_n) begin
            miso <= 0;
        end else begin
            if (state == READ_DATA) begin
                miso <= data[DATA_WIDTH-1 - bit_count];
            end else begin
                miso <= 0;
            end
        end
    end

endmodule
