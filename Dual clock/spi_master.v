module spi_master (
    input  wire       SCLK,
    input  wire       rst_n,
    input  wire       fifo_empty,
    input  wire [7:0] fifo_data,
    output reg        fifo_rd_en,
    output reg        MOSI,
    output reg        SS
);

reg [2:0] bit_cnt;
reg [7:0] shift_reg;
reg load_pending;

always @(posedge SCLK or negedge rst_n) begin
    if (!rst_n) begin
        bit_cnt    <= 0;
        shift_reg  <= 0;
        MOSI       <= 0;
        SS         <= 1;
        fifo_rd_en <= 0;
	load_pending <=0;
    end
    else begin
        fifo_rd_en <= 0;

        if (!fifo_empty && bit_cnt == 0 &&SS==1 && !load_pending) begin
            fifo_rd_en <= 1;
            load_pending <= 1;
        end

	else if(load_pending) begin
		shift_reg <=fifo_data;
		bit_cnt <=7;
		MOSI <=fifo_data[7];
		SS <=0;
		load_pending <=0;
	end
	else if(bit_cnt !=0)begin
            MOSI      <= shift_reg[bit_cnt-1];
            bit_cnt   <= bit_cnt - 1;
        end
        else if (bit_cnt ==0 && SS==0) begin
            SS <= 1;
        end
    end
end

endmodule

/*module spi_master (
    input  wire       SCLK,
    input  wire       rst_n,
    input  wire       fifo_empty,
    input  wire [7:0] fifo_data,
    output reg        fifo_rd_en,
    output reg        MOSI,
    output reg        SS
);

reg [1:0] state;
reg [2:0] bit_cnt;
reg [7:0] shift_reg;
 State encoding (pure Verilog) 
parameter IDLE  = 2'b00;
parameter LOAD  = 2'b01;
parameter SHIFT = 2'b10;
parameter DONE  = 2'b11;

always @(posedge SCLK or negedge rst_n) begin
    if (!rst_n) begin
        state      <= IDLE;
        bit_cnt    <= 3'd0;
        shift_reg  <= 8'd0;
        MOSI       <= 1'b0;
        SS         <= 1'b1;
        fifo_rd_en <= 1'b0;
    end else begin
        fifo_rd_en <= 1'b0;

        case (state)

        // --------------------------------
        IDLE: begin
            SS <= 1'b1;
            if (!fifo_empty) begin
                fifo_rd_en <= 1'b1;   // request FIFO read
                state      <= LOAD;
            end
        end

        // --------------------------------
        LOAD: begin
            shift_reg <= fifo_data;   // FIFO data valid now
            bit_cnt   <= 3'd7;
            MOSI      <= fifo_data[7]; // preload MSB
            SS        <= 1'b0;         // assert slave select
            state     <= SHIFT;
        end

        // --------------------------------
        SHIFT: begin
            if (bit_cnt != 0) begin
                bit_cnt <= bit_cnt - 1'b1;
                MOSI    <= shift_reg[bit_cnt - 1'b1];
            end else begin
                state <= DONE;
            end
        end

        // --------------------------------
        DONE: begin
            SS    <= 1'b1;   // end SPI frame
            state <= IDLE;
        end

        endcase
    end
end

endmodule*/

