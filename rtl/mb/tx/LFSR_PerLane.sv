//implementing LFSR Per-Lane
module LFSR_PerLane #( parameter WIDTH = 23,         // Width of the LFSR
                       parameter Seed  = 23'h1DBFBC ) 

(
    input  logic                 MB_CLK        ,        // Clock signal
    input  logic                 RST_n         ,        // Asynchronous reset
    input  logic [4:0]           Opcode_Synch  ,        // to reset the LFSR on state transitions
    input  logic                 EN            ,        // Enable signal
    input  logic                 PN_EN         ,        // to know if it's data scrambling or LFSR test
    input  logic                 Data_In       ,        // input bit of each lane
    output logic                 Data_Out      ,        // output scrambled bit of each lane
    output logic [7:0]           Valid         ,
    output logic                 VLD_SER_EN
);


//internal signals
logic [WIDTH-1:0] LFSR_REG      ;
logic [4:0] prev_LTSM_state     ;
localparam Tap_Points = 23'h210124;
integer i                       ;    
logic Data_Out_reg;  // Register for sequential behavior


//*********************Main Logic******************************//

always_ff @(posedge MB_CLK or negedge RST_n) 
  begin
    if (!RST_n) begin
		LFSR_REG <= Seed;
		prev_LTSM_state<='b0;   // RESET state
        Data_Out_reg <= 1'b0;     // Reset Data_Out register
		Valid <= 0;
		VLD_SER_EN <= 0;
    end 

    else if (Opcode_Synch != prev_LTSM_state)       //LFSR REG should be reseted with each LTSM state change
      begin   
	LFSR_REG <= Seed;
	prev_LTSM_state<=Opcode_Synch;		
        Data_Out_reg <= 1'b0;     // Reset Data_Out register   
      end 

    else if (EN) 
      begin
	LFSR_REG[0]<=LFSR_REG[WIDTH-1];

        for (i= 1; i < WIDTH; i++) 
          begin
	    if(Tap_Points[i])
	       LFSR_REG[i]<=LFSR_REG[i-1]^LFSR_REG[WIDTH-1];
	    else
	       LFSR_REG[i]<=LFSR_REG[i-1];  
           end

        if(PN_EN)
          begin
            // Sequential update of Data_Out when PN_EN is active (LFSR 4K test)
            Data_Out_reg <= Data_In ^ LFSR_REG[WIDTH-1];

            // Valid output & Serializer enable signals
            Valid <= 8'b00001111;
            VLD_SER_EN <= 1;
          end
        else
          begin
            Valid <= 8'b0;
            VLD_SER_EN <= 0;
          end

      end 

    else           //bypassing the data
     begin
       Valid <= 8'b0;
       VLD_SER_EN <= 0;
       Data_Out_reg <= 1'b0;     // Reset Data_Out register
     end
   
 end


// Assign Data_Out
assign Data_Out = PN_EN ? Data_Out_reg : (EN ? (Data_In ^ LFSR_REG[WIDTH-1]) : Data_In);


endmodule