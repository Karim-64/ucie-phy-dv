//implementing LFSR Per-Lane
module LFSR_PerLane_MBRX #( parameter WIDTH = 23,         // Width of the LFSR
                       parameter Seed  = 23'h1DBFBC ) 

(
    input  logic                 MB_CLK        ,        // Clock signal
    input  logic                 RST_n         ,        // Asynchronous reset
    input  logic [4:0]           Opcode_Synch  ,        // to reset the LFSR on state transitions
    input  logic                 EN            ,        // Enable signal
    input  logic                 Data_In       ,        // input bit of each lane
    output logic                 Data_Out               // output scrambled bit of each lane
);


//internal signals

logic [WIDTH-1:0] LFSR_REG        ;
logic [4:0] prev_LTSM_state       ;
localparam Tap_Points = 23'h210124;
integer i                         ;    


//*********************Main Logic******************************//

always_ff @(posedge MB_CLK or negedge RST_n) 
  begin
    if (!RST_n) begin
	       LFSR_REG <= Seed;
	       prev_LTSM_state<='b0;   

   end else if (Opcode_Synch!=prev_LTSM_state) begin      //LFSR REG should be reseted with each LTSM state change   
	      
        LFSR_REG <= Seed;
	      prev_LTSM_state<=Opcode_Synch;		   

    end else if (EN) begin
	      
        LFSR_REG[0]<=LFSR_REG[WIDTH-1];

        for (i= 1; i < WIDTH; i++) begin
	             if(Tap_Points[i])
	               LFSR_REG[i]<=LFSR_REG[i-1]^LFSR_REG[WIDTH-1];
	             else
	               LFSR_REG[i]<=LFSR_REG[i-1];  
        end

    end 
   
 end

 assign Data_Out= EN ? Data_In^LFSR_REG[WIDTH-1] : Data_In;	


endmodule