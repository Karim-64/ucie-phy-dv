//implementing TX Controller
module TX_Controller (   
  input              MB_CLK, 
  input      [4:0]   Opcode_Synch,
  input              Start_LTSM_Synch,
  input              Done_1,
  input              Done_2,
  input              Done_3,
  input              EMPTY,   //from Async_FIFO
  input              EMPTY_2,   //from Async_FIFO_2 of stall hs
  input      [1:0]   width_degrade_LTSM_Synch,

  output   reg       VALTRAIN_EN,
  output   reg       BYTE_MAP_EN,
  output   reg       PerLaneID_EN,
  
  output   reg       PN_EN, 
  output   reg       Scramble_EN,

  output   reg [1:0] SEL_1,
  output   reg       SEL_2,
  output   reg       SEL_5,     //byte to lane mapper data input mux selection
  output   reg       End_LTSM,
  output   reg       RD_EN,     // to first fifo of pl_trdy
  output   reg       RD_EN_2    // to second fifo of pl_stallreq     
  );
  

  localparam  [2:0]    IDLE       = 3'b0,
                       VALTRAIN   = 3'b001,
		                   PerLaneID  = 3'b010,			             
	                     LFSR       = 3'b011,			             
		                   ACTIVE     = 3'b100;
		       	             
					            	             
   reg      [2:0]   current_state,
                    next_state ;

   logic [3:0]  counter = 4'b0;
   logic [12:0] LFSR_counter = 13'b0;
   logic       flag = 1'b0;
   logic       flag_LFSR = 1'b0;
   logic       flag_sel = 1'b0;

// state transition 		
always @(posedge MB_CLK) begin

   current_state <= next_state ;

   if(current_state == IDLE) begin 

     flag_sel<='b0;

     if((Opcode_Synch == 5'b10110) && !EMPTY_2 && (width_degrade_LTSM_Synch != 2'b00))

     flag_sel <= 1'b1;

   end 


   if(Done_1 || Done_2 || Done_3)   // Sending an End signal after all bytes are finally serialized and sent successfully
    begin
      if( counter == 4'b0111 )
        begin
          End_LTSM <= 1'b1;
        end
      else
        begin
          counter <= counter + 1'b1;
        end
    end
   else
     counter <= 4'b0;



   if( current_state == LFSR )
    begin
      if(LFSR_counter == 13'b1000000000000)
        begin
          End_LTSM <= 1'b1;      // Mark process as done after 4K iterations
        end
       else
         begin
           LFSR_counter <= LFSR_counter + 1'b1;
           if(LFSR_counter == 13'b0111111111111)
              flag_LFSR <= 1'b1;
           else
              flag_LFSR <= 1'b0;
         end
    end
   else
     LFSR_counter <= 13'b0;



   if( current_state == ACTIVE )
      flag <= 1'b1;
   else
      flag <= 1'b0;

   if( next_state == IDLE ) begin
      End_LTSM <= 1'b0;
      counter <= 4'b0;
      LFSR_counter <= 13'b0;
      flag <= 1'b0;
      flag_LFSR <= 1'b0;
   end 


 end
 

// next_state & outputs logic
always @(*) begin

	VALTRAIN_EN = 1'b0;
	BYTE_MAP_EN = 1'b0;
	PerLaneID_EN = 1'b0;
	PN_EN = 1'b0;
	Scramble_EN = 1'b0;
	SEL_1 = 2'b0;
	SEL_2 = 1'b0;
	SEL_5 = 1'b0;
	RD_EN = 1'b0;
	RD_EN_2 = 1'b0;

   case(current_state)

    IDLE  : begin

              VALTRAIN_EN = 1'b0;
              BYTE_MAP_EN = 1'b0;
              PerLaneID_EN = 1'b0;

              PN_EN = 1'b0;
              Scramble_EN = 1'b0;

              SEL_1 = 2'b0;
              SEL_2 = 1'b0;
              SEL_5 = 1'b0;
              RD_EN = 1'b0;
              RD_EN_2 = 1'b0;


              if ( (Opcode_Synch == 5'b00000) || (Opcode_Synch == 5'b00001) || (Opcode_Synch == 5'b00010) || (Opcode_Synch == 5'b00011) 
                   || (Opcode_Synch == 5'b00100) || (Opcode_Synch == 5'b01010) || (Opcode_Synch == 5'b01011) || (Opcode_Synch == 5'b01100) 
                   || (Opcode_Synch == 5'b10100) || (Opcode_Synch == 5'b10101) || (Opcode_Synch == 5'b10111) || (Opcode_Synch == 5'b11000) ) 

                 next_state = IDLE ;    // Specify IDLE / RESET operation    


              else if( ( (Opcode_Synch == 5'b00101) || (Opcode_Synch == 5'b01000) || (Opcode_Synch == 5'b01101) || (Opcode_Synch == 5'b01110) )
                         && Start_LTSM_Synch) 

	               next_state = VALTRAIN ;   // Specify Valid training pattern operation
			      
     
              else if( ( (Opcode_Synch == 5'b00110) || (Opcode_Synch == 5'b00111) ) && Start_LTSM_Synch && (width_degrade_LTSM_Synch != 2'b00) ) 
                 next_state = PerLaneID ;   // Specify D2C with perlane pattern operation


              else if( ( (Opcode_Synch == 5'b01001) || (Opcode_Synch == 5'b01111) || (Opcode_Synch == 5'b10000) || (Opcode_Synch == 5'b10001) 
                          || (Opcode_Synch == 5'b10010) || (Opcode_Synch == 5'b10011) ) && Start_LTSM_Synch && (width_degrade_LTSM_Synch != 2'b00) ) 

                 next_state = LFSR ;       // Specify D2C with LFSR pattern operation
                 

              else if( (Opcode_Synch == 5'b10110) && !EMPTY && (width_degrade_LTSM_Synch != 2'b00) ) begin    
                 RD_EN = 1'b1;
                 RD_EN_2 = 1'b0;
                 SEL_5 = 1'b0;
                 next_state = ACTIVE ;    // Specify active transfer operation

              end else if( (Opcode_Synch == 5'b10110) && !EMPTY_2 && (width_degrade_LTSM_Synch != 2'b00) ) begin    
                 RD_EN = 1'b0;
                 RD_EN_2 = 1'b1;
                 SEL_5 = 1'b1;
                 next_state = ACTIVE ;    // Specify active transfer operation
        
              end else 
                 next_state = IDLE ;  
             end
             

  VALTRAIN : begin
           
               VALTRAIN_EN = 1'b1;
               if(End_LTSM)
                begin
                 next_state = IDLE ;
                 VALTRAIN_EN = 1'b0;
                end
               else
                 next_state = VALTRAIN ;
             end

  PerLaneID : begin
              
               PerLaneID_EN = 1'b1;
               SEL_1 = 2'b10;
               SEL_2 = 1'b1;
               if(End_LTSM)
                begin
                 next_state = IDLE ;
                 PerLaneID_EN = 1'b0;
                 SEL_2 = 1'b0;
                 SEL_1 = 2'b00;
                end
               else
                 next_state = PerLaneID ;
             end

  LFSR  : begin
          
           if(!End_LTSM && !flag_LFSR)
             begin
               PN_EN = 1'b1;
               Scramble_EN = 1'b1;
               SEL_1 = 2'b11;
             end
 
           if(flag_LFSR)
             begin
               PN_EN = 1'b1;
               Scramble_EN = 1'b0;
               SEL_1 = 2'b11;
             end

           if(End_LTSM)
            begin
              next_state = IDLE ;
              PN_EN = 1'b0;
              Scramble_EN = 1'b0;
              SEL_1 = 2'b00;
            end
           else
              next_state = LFSR ;
          end
           

   ACTIVE  : begin

              RD_EN = 1'b0;
              RD_EN_2 = 1'b0;

              if(flag_sel) begin
                SEL_5 = 1'b1;
              end else begin
                SEL_5 = 1'b0;
              end

              if(!End_LTSM)
               begin
                BYTE_MAP_EN = 1'b1;
                SEL_1 = 2'b01;
               end

              if(!End_LTSM && flag) begin
                Scramble_EN = 1'b1;
                SEL_1 = 2'b01;
              end

              if(End_LTSM)
               begin
                 next_state = IDLE ;
                 BYTE_MAP_EN = 1'b0;
                 SEL_1 = 2'b00;
                 Scramble_EN = 1'b0;
               end
              else
                 next_state = ACTIVE ;
             end
            
  
  default : begin 
              VALTRAIN_EN = 1'b0;
              BYTE_MAP_EN = 1'b0;
              PerLaneID_EN = 1'b0;

              PN_EN = 1'b0;
              Scramble_EN = 1'b0;

              SEL_1 = 2'b0;
              SEL_2 = 1'b0;
              SEL_5 = 1'b0;
	            RD_EN = 1'b0;
	            RD_EN_2 = 1'b0;

              next_state = IDLE ;	
            end	 
  
  endcase

end	


endmodule