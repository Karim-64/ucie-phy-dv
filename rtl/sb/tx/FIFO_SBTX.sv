/*---------Description------------------//

this Module Saves Messages originating from D2D and implements
a priority mechanism to prevent Req/Resp D2D messages
from being blocked by unconstrained Local RARs.

//---------------------------------------*/

module FIFO_SBTX #(parameter FIFO_WIDTH=64, FIFO_DEPTH=64)
(
    input  logic clk, rst_n, wr_en, rd_en,
    input  logic [FIFO_WIDTH-1:0] data_in,
    input  logic UIE,
    input  logic Data_Marker, Reg_Acc_Marker, Reg_Acc_Data_Marker, Comp_Marker, Req_Resp_Marker,
    output logic [FIFO_WIDTH-1:0] data_out,
    output logic Data_Marker_Out, Reg_Acc_Marker_Out, Reg_Acc_Data_Marker_Out, Comp_Marker_Out,
    output logic empty, rd_ack
);

//***************** Internal Signals *****************//
localparam max_fifo_addr = $clog2(FIFO_DEPTH);
logic [max_fifo_addr-1:0] count;
logic [max_fifo_addr-1:0] wr_ptr, rd_ptr;

logic [max_fifo_addr-1:0] head_ptr, reg_acc_ptr,last_head_ptr;
logic full,Priority_Valid,RAR_read;

logic [FIFO_WIDTH-1:0] mem [FIFO_DEPTH-1:0];
logic [FIFO_DEPTH-1:0] Data_Marker_Reg, Reg_Acc_Marker_Reg, Reg_Acc_Data_Marker_Reg, Comp_Marker_Reg;

logic WR_Cond,RD_Cond;
logic RD_Till_RAR,RD_Req_Resp;
logic Reset_RAR_ptr;

////

//Generating Conditions//

assign WR_Cond = (wr_en && ~UIE && count < FIFO_DEPTH);
assign RD_Cond = (rd_en && count != 0);
assign RD_Till_RAR = ((reg_acc_ptr != FIFO_DEPTH-1) && rd_ptr < reg_acc_ptr && ~Priority_Valid);
assign RD_Req_Resp = (head_ptr != FIFO_DEPTH-1);
assign Reset_RAR_ptr = (RD_Cond & ~RD_Till_RAR & ~RD_Req_Resp & (rd_ptr == reg_acc_ptr));

////


// Write logic with priority handling
always_ff @(posedge clk or negedge rst_n) begin               

    if (!rst_n) begin

        wr_ptr <= 0;
        head_ptr <=FIFO_DEPTH-1;
        reg_acc_ptr <=FIFO_DEPTH-1;
        
        Data_Marker_Reg <='b0;
        Reg_Acc_Marker_Reg <= 'b0;
        Reg_Acc_Data_Marker_Reg <= 'b0;
        Comp_Marker_Reg <='b0;

    end else begin 
    
        if (WR_Cond) begin
        mem[wr_ptr] <= data_in;
        Data_Marker_Reg[wr_ptr] <= Data_Marker;
        Reg_Acc_Marker_Reg[wr_ptr] <= Reg_Acc_Marker;
        Reg_Acc_Data_Marker_Reg[wr_ptr] <= Reg_Acc_Data_Marker;
        Comp_Marker_Reg[wr_ptr] <= Comp_Marker;
        
        if (Req_Resp_Marker && (reg_acc_ptr != FIFO_DEPTH-1))
            head_ptr    <= wr_ptr;    // Prioritize Req/Resp messages only over Reg_Acc messages
        else if (Reg_Acc_Marker && (reg_acc_ptr == FIFO_DEPTH-1))
            reg_acc_ptr <= wr_ptr; // Track first Reg_Acc message
        
        wr_ptr <= wr_ptr + 1;

       end
       
       if(Priority_Valid) head_ptr <= FIFO_DEPTH-1; // Reset priority as the Req/Resp message is already read
       
       if(Reset_RAR_ptr)  reg_acc_ptr <= FIFO_DEPTH-1;
 
       end 

end

// Read logic with priority handling
always_ff @(posedge clk or negedge rst_n) begin
    
	if (!rst_n) begin

        rd_ptr <= 0;
        rd_ack <= 0;
        data_out <= 0;
        Data_Marker_Out <= 0;
        Reg_Acc_Marker_Out <= 0;
        Reg_Acc_Data_Marker_Out <= 0;
        Comp_Marker_Out <= 0;
        
        Priority_Valid<=1'b0;
		last_head_ptr<=-1;

    end else if (RD_Cond) begin

		rd_ack <= 1'b1;

		data_out <= mem[rd_ptr];
        Data_Marker_Out <= Data_Marker_Reg[rd_ptr];
        Reg_Acc_Marker_Out <= Reg_Acc_Marker_Reg[rd_ptr];
        Reg_Acc_Data_Marker_Out <= Reg_Acc_Data_Marker_Reg[rd_ptr];
        Comp_Marker_Out <= Comp_Marker_Reg[rd_ptr];

        if (RD_Till_RAR) begin
             // Read sequentially up to first Reg_Acc message
            rd_ptr <= rd_ptr + 1; 

        end else if (RD_Req_Resp) begin
        // Read Req/Resp message only if it exists and a Reg_Acc was skipped
        data_out <= mem[head_ptr];
        Data_Marker_Out <= Data_Marker_Reg[head_ptr];
        Reg_Acc_Marker_Out <= Reg_Acc_Marker_Reg[head_ptr];
        Reg_Acc_Data_Marker_Out <= Reg_Acc_Data_Marker_Reg[head_ptr];
        Comp_Marker_Out <= Comp_Marker_Reg[head_ptr];
		last_head_ptr<=head_ptr;
        Priority_Valid<=1'b1;
        
		end else begin
        // Normal sequential reading
        rd_ptr <= rd_ptr + 1;
       
		if(rd_ptr == last_head_ptr-1 && Priority_Valid) begin 
         Priority_Valid<=1'b0;
		 rd_ptr <= rd_ptr + 2;
         last_head_ptr<=FIFO_DEPTH-1;
		end 

        end
        
    end else begin

        rd_ack <= 1'b0;

    end

end


always_ff  @(posedge clk or negedge rst_n) begin

	if (!rst_n) begin

		count <= 0;

	end else begin

		if	(({wr_en,rd_en} == 2'b10) && !full && ~UIE) 
			count <= count + 1;
		else if (({wr_en,rd_en} == 2'b01) && !empty)
			count <= count - 1;
		else if (({wr_en,rd_en} == 2'b11) && !empty && full)
			count <= count - 1;
		else if	(({wr_en,rd_en} == 2'b11) && !full && empty && ~UIE) 
			count <= count + 1;
		
	end

end

assign full             = (count == FIFO_DEPTH)? 1'b1 : 1'b0; 
assign empty            = (count == 0)? 1'b1 : 1'b0;


endmodule