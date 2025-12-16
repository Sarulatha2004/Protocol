module apb_master(
 input pclk,
 input presetn,
 input r_w,
 input transfer,
 input ready,
 input [7:0]write_paddr,
 input [7:0]write_data,
 input [7:0]read_paddr,
 input [7:0]prdata,
 output reg psel,
 output reg penable,
 output reg pwrite,
 output reg [7:0]paddr,
 output reg [7:0]pwrite_data,
 output reg [7:0]read_data_out
);


reg [1:0]state,next_state;
parameter IDLE=2'b00;
parameter SETUP=2'b01;
parameter ACCESS =2'b10;

always @ (posedge pclk or negedge presetn)
begin
	if(!presetn)
		state <= IDLE;
	else
		state <= next_state;
end

always @ (*) begin
	case(state)
		IDLE:
			next_state = transfer ? SETUP:IDLE;
		SETUP:
			next_state = ACCESS;
		ACCESS:
			next_state = (ready==0)? ACCESS:(transfer ? SETUP: IDLE);
	endcase
end

always @(*) begin
	psel = (state != IDLE);
	penable = (state == ACCESS);
        
	
	pwrite =1'b0;
	paddr =8'b0;
	pwrite_data = 8'b0;
	read_data_out = 8'b0;

	if(state == SETUP  ||  state == ACCESS)
	begin
		pwrite = r_w;
                pwrite_data = r_w ? write_data:8'b0;
		paddr = r_w ? write_paddr: read_paddr;
                read_data_out = r_w ? 8'b0:prdata;
	end
end
endmodule
