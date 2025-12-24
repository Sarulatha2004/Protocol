module apb_slave (
    input  wire        PCLK,
    input  wire        PRESETn,
    input  wire        PSEL,
    input  wire        PENABLE,
    input  wire        PWRITE,
    input  wire [7:0]  PADDR,
    input  wire [7:0]  PWDATA,
    input wire fifo_full,
    output reg         fifo_wr_en,
    output reg  [7:0]  fifo_wr_data
);

always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        fifo_wr_en   <= 1'b0;
        fifo_wr_data <= 8'd0;
    end
    else begin
        fifo_wr_en <= 1'b0;

        if (PSEL && PENABLE && PWRITE && !fifo_full) begin
            fifo_wr_en   <= 1'b1;
            fifo_wr_data <= PWDATA;
        end
    end
end

endmodule
