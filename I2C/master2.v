module i2c_master2(
  input wire clk,
  input wire reset,
  output reg i2c_sda,
  output wire i2c_scl
);

localparam IDLE=0;
localparam START=1;
localparam ADDRESS =2;
localparam R_W=3;
localparam ADDR_ACK=4;
localparam DATA=5;
localparam DATA_ACK=6;
localparam STOP=7;
localparam POINTER=8;

reg [3:0]state;
reg [6:0] count;
reg [7:0] addr;
reg [7:0] data;
reg i2c_scl_enable =0;
reg [7:0]pointer_addr;
assign i2c_scl = (i2c_scl_enable ==0 ) ? 1: ~clk;

always @ (negedge clk)
begin
	if(reset == 1)
	begin
		i2c_scl_enable <= 0;
	end
	else 
	begin
		if((state == IDLE) || (state == START) || (state == STOP))
		begin
			i2c_scl_enable <= 0;
		end
		else
		begin
			i2c_scl_enable <= 1 ;
		end
	end
end
always @ (posedge clk)
begin
        if(reset)
        begin
                state <= IDLE;
                i2c_sda <= 1;
                addr <= 7'h50;
                count <= 8'd0;
                data <=8'haa;
		pointer_addr <= 8'h10;
        end
        else
        begin
                case(state)
                        IDLE:
                        begin
                                i2c_sda <=1;
                                state <= START;
                        end
                         START:
                        begin
                                i2c_sda <=0;
                                state <= ADDRESS;
                                count <=6;
                        end
                        ADDRESS:
                        begin
                                i2c_sda <= addr[count];
                                if(count ==0)
                                        state <= R_W;
                                else
                                        count <= count - 1;
                        end
                        R_W:
                        begin
                                i2c_sda <=1;
                                state <= ADDR_ACK;
                        end
                        ADDR_ACK:
                        begin
                                state <= POINTER;
                                count <=7;
                        end

			POINTER:
			begin
				i2c_sda <= pointer_addr[count];
				if(count == 0)
					state <= DATA;
				else
					count <= count -1;
			end

                        DATA:
                        begin
                                i2c_sda <= data[count];
                                if(count == 0)
                                        state <= DATA_ACK;
                                else
                                        count <= count-1;
                        end
                         DATA_ACK:
                        begin
                                state <= STOP;
                        end

                        STOP:
                        begin
                                i2c_sda <= 1;
                                state <= IDLE;
                        end
                endcase
        end
end




endmodule

