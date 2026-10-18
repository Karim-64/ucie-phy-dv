import Universal_pkg ::* ; 

module Per_Lane_MBRX #(parameter NUM_LANES=16)
(
    
    input  logic CLK,RST_n                                   , // MB CLK
    input  logic Width_Degrade_Update                        , // signal to indicate that there is a change in the operational width
    input  logic [WIDTH_DEGRADE_LENGTH-1:0] Width_Degrade    , // only half the lanes are used (011-> 15:0,001->7:0 , 010->15:8)
    input  LTSM_states LTSM_State                            , 
    input  logic [Pattern_Length-1:0] Lanes_IDs [NUM_LANES-1:0], // for the Lane_ID test
    input  logic [NUM_LANES-1:0] LFSR_Pattern                , // for the LFSR test
    input  logic [NUM_LANES-1:0] Compare_ip                  , // data lanes 
    input  logic [ERROR_THRESHOLD_LENGTH-1:0] Error_Threshold, // Threshold to determine Functional Lanes for LFSR test
    input  logic Comparison_Type                             , // signal to indicate which Test is currently needed to be carried (1--> Lane_ID, 0--> LFSR)
    input  logic Comparison_EN                               , 
    output logic Comparison_Done                             , // Signal that mark sending the Test Result to the Controller to be encoded in a SB Message
    output logic [NUM_LANES-1:0] Faulty_Lanes                  // should be sent to the transmitter (of remote die) to determine its functional lanes
                
);


//********************Internal Signals**********************//

logic [WIDTH_DEGRADE_LENGTH-1:0] Width_Degrade_reg;

bit   [NUM_LANES-1:0] Error_Bits_Lane_ID                        ; 
logic [ERROR_THRESHOLD_LENGTH:0] Error_Bits_LFSR [NUM_LANES-1:0];  // to store the number of errors for each lane 13 BITS IN CASE LANE IS INVERTED !
bit   [NUM_LANES-1:0] Lane_ID_Flag            ;
bit   [NUM_LANES-1:0] LFSR_Flag               ;
bit   Test_Processing                         ;

integer s,j                                   ;                      // integers for Reseting each-lane Counter and each-bit Comparison


bit [$clog2(Iteration_Count_Lane_ID)-1:0] Iteration_Counter_Lane_ID ; // counters necessary for the Tests
bit [$clog2(Iteration_Count_LFSR)-1:0] Iteration_Counter_LFSR       ;
bit [$clog2(Suff_Frames):0] Cons_Counter [NUM_LANES-1:0]            ; 
bit [$clog2(Pattern_Length)-1:0] Pattern_Counter                    ; 

//*********************************************************//


//****************************Width_Degradation_Update**************************************//

always_ff @(posedge CLK or negedge RST_n) begin 

   if(!RST_n) begin

      Width_Degrade_reg <= All_Lanes;
      
   end else begin 

    if (LTSM_State==RESET) begin

      Width_Degrade_reg <= All_Lanes;
      
    end

   else if (Width_Degrade_Update & !(Test_Processing)) begin   // this condition implies that the update of Width_Degrade should not be in middle of a test

     Width_Degrade_reg <= Width_Degrade;

   end 

   end 

end

//*****************************************************************************************//


//*****************************Main Logic**************************************************//

always_comb begin 

  //Default Values 
  Error_Bits_Lane_ID = 'b0;     
  LFSR_Flag = 'b0;

case(Width_Degrade_reg)

Least_Sig_Lanes: begin

for(j=0;j<NUM_LANES/2;j=j+1) begin

   Error_Bits_Lane_ID[j] =(Compare_ip[j]!=Lanes_IDs[j][Pattern_Counter])? 1'b1:1'b0;     
   LFSR_Flag[j]=(Compare_ip[j]!=LFSR_Pattern[j])? 1'b1:1'b0;

end 

end 

Most_Sig_Lanes: begin

for(j=NUM_LANES/2;j<NUM_LANES;j=j+1) begin

   Error_Bits_Lane_ID[j] =(Compare_ip[j]!=Lanes_IDs[j][Pattern_Counter])? 1'b1:1'b0;     
   LFSR_Flag[j]=(Compare_ip[j]!=LFSR_Pattern[j])? 1'b1:1'b0;

end 

end 

All_Lanes: begin

for(j=0;j<NUM_LANES;j=j+1) begin

   Error_Bits_Lane_ID[j] =(Compare_ip[j]!=Lanes_IDs[j][Pattern_Counter])? 1'b1:1'b0;     
   LFSR_Flag[j]=(Compare_ip[j]!=LFSR_Pattern[j])? 1'b1:1'b0;

end 

end

default: begin

  Error_Bits_Lane_ID = 'b0;     
  LFSR_Flag = 'b0;

end 

endcase

end 

 always_ff @(posedge CLK or negedge RST_n) begin    //**********outputs_transition************//

  if(!RST_n) begin 

  for(s=0;s<NUM_LANES;s=s+1)
  Error_Bits_LFSR[s] <='b0;
  Lane_ID_Flag       <='b0;
  Faulty_Lanes       <='b0;
  Comparison_Done    <='b0; 
   
  end else if (Comparison_EN) begin 

  if(Comparison_Type) begin 

      case(Width_Degrade_reg)

      Least_Sig_Lanes: begin
        
        for(s=0;s<NUM_LANES/2;s=s+1) begin

         if(Error_Bits_Lane_ID[s]==1'b1)  
            Lane_ID_Flag[s]<=1'b1;

        end 
        
      end 

      Most_Sig_Lanes: begin
       
       for(s=NUM_LANES/2;s<NUM_LANES;s=s+1) begin
         
         if(Error_Bits_Lane_ID[s]==1'b1)  
            Lane_ID_Flag[s]<=1'b1;

       end 

      end 

      All_Lanes: begin
      
      for(s=0;s<NUM_LANES;s=s+1) begin
        
        if(Error_Bits_Lane_ID[s]==1'b1)  
            Lane_ID_Flag[s]<=1'b1;

      end 

      end 

      endcase

      if(Pattern_Counter==Pattern_Length-1) begin 

         Lane_ID_Flag<=0;

         if(Iteration_Counter_Lane_ID==Iteration_Count_Lane_ID-1) begin 

            Comparison_Done    <='b1;
        
            case(Width_Degrade_reg)

               Least_Sig_Lanes: begin
        
                  for(s=0;s<NUM_LANES/2;s=s+1) begin

                     if((Cons_Counter[s]==Suff_Frames) || ((Cons_Counter[s]==Suff_Frames-1) && !(Lane_ID_Flag[s] || Error_Bits_Lane_ID[s])))
                       Faulty_Lanes[s]<='b0;
                     else
                       Faulty_Lanes[s]<='b1;

                  end 

                  Faulty_Lanes[NUM_LANES-1:NUM_LANES/2] <=8'hFF; // Set the most significant lanes to 0 since they are not tested
        
               end 

               Most_Sig_Lanes: begin
       
                  for(s=NUM_LANES/2;s<NUM_LANES;s=s+1) begin
         
                     if((Cons_Counter[s]==Suff_Frames) || ((Cons_Counter[s]==Suff_Frames-1) && !(Lane_ID_Flag[s] || Error_Bits_Lane_ID[s])))
                       Faulty_Lanes[s]<='b0;
                     else
                       Faulty_Lanes[s]<='b1;

                  end 
                  Faulty_Lanes[(NUM_LANES/2)-1:0] <=8'hFF; // Set the least significant lanes to 0 since they are not tested
               end 

               All_Lanes: begin
      
                  for(s=0;s<NUM_LANES;s=s+1) begin
        
                     if((Cons_Counter[s]==Suff_Frames) || ((Cons_Counter[s]==Suff_Frames-1) && !(Lane_ID_Flag[s] || Error_Bits_Lane_ID[s])))
                       Faulty_Lanes[s]<='b0;
                     else
                       Faulty_Lanes[s]<='b1;

                  end 

               end 

               endcase
            
            end 

      end

  end else begin 

    case(Width_Degrade_reg)

         Least_Sig_Lanes: begin
        
           for(s=0;s<NUM_LANES/2;s=s+1) begin

           if(LFSR_Flag[s]) Error_Bits_LFSR[s]<=Error_Bits_LFSR[s]+12'b1;
             
           end 
        
         end 

         Most_Sig_Lanes: begin
       
           for(s=NUM_LANES/2;s<NUM_LANES;s=s+1) begin

            if(LFSR_Flag[s]) Error_Bits_LFSR[s]<=Error_Bits_LFSR[s]+12'b1;

           end 

         end 

         All_Lanes: begin
      
           for(s=0;s<NUM_LANES;s=s+1) begin

            if(LFSR_Flag[s]) Error_Bits_LFSR[s]<=Error_Bits_LFSR[s]+12'b1;

           end 

         end 

      endcase
       
    if(Iteration_Counter_LFSR==Iteration_Count_LFSR-1) begin 
        Comparison_Done    <='b1;

        case(Width_Degrade_reg)

         Least_Sig_Lanes: begin
        
           for(s=0;s<NUM_LANES/2;s=s+1) begin
             
             if(Error_Bits_LFSR[s] + LFSR_Flag[s] <= Error_Threshold)
                Faulty_Lanes[s]<='b0;
             else
                Faulty_Lanes[s]<='b1;

           end 
            Faulty_Lanes[NUM_LANES-1:(NUM_LANES/2)] <=8'hFF; // Set the most significant lanes to 0 since they are not tested
         end 

         Most_Sig_Lanes: begin
       
           for(s=NUM_LANES/2;s<NUM_LANES;s=s+1) begin

              if(Error_Bits_LFSR[s] + LFSR_Flag[s] <= Error_Threshold)
                Faulty_Lanes[s]<='b0;
             else
                Faulty_Lanes[s]<='b1;
         
            end 
            Faulty_Lanes[(NUM_LANES/2)-1:0] <=8'hFF; // Set the least significant lanes to 0 since they are not tested
         end 

         All_Lanes: begin
      
           for(s=0;s<NUM_LANES;s=s+1) begin

              if(Error_Bits_LFSR[s] + LFSR_Flag[s] <= Error_Threshold)
                Faulty_Lanes[s]<='b0;
             else
                Faulty_Lanes[s]<='b1;

            end 

         end 

      endcase

     end 

   end 

  end else begin 

  Faulty_Lanes       <='b0;
  Comparison_Done    <='b0;
  Lane_ID_Flag       <='b0; 
  for(s=0;s<NUM_LANES;s=s+1)
     Error_Bits_LFSR[s] <='b0;

  end 

end


always_ff @(posedge CLK or negedge RST_n) begin    //**********Counters_transition************//

  if(!RST_n) begin 

  Iteration_Counter_Lane_ID <='b0 ;
  Iteration_Counter_LFSR    <='b0 ;
  Pattern_Counter           <='b0 ;  
  Test_Processing           <='b0 ; 
  for(s=0;s<NUM_LANES;s=s+1)
      Cons_Counter[s]<='b0;

  end else if (Comparison_EN) begin 
   
   Test_Processing<='b1;

   if(Comparison_Type) begin 

      Pattern_Counter<=Pattern_Counter+1;

      if(Pattern_Counter==Pattern_Length-1) begin 

         Iteration_Counter_Lane_ID<=Iteration_Counter_Lane_ID+1; 
         
         if(Iteration_Counter_Lane_ID==Iteration_Count_Lane_ID-1)
            Test_Processing<='b0;

        case(Width_Degrade_reg)

         Least_Sig_Lanes: begin
        
           for(s=0;s<NUM_LANES/2;s=s+1) begin

            if(Cons_Counter[s]<Suff_Frames)

              if((Lane_ID_Flag[s] || Error_Bits_Lane_ID[s])) 
                Cons_Counter[s]<='b0;
              else
                Cons_Counter[s]<=Cons_Counter[s]+1;
             
           end 
        
         end 

         Most_Sig_Lanes: begin
       
           for(s=NUM_LANES/2;s<NUM_LANES;s=s+1) begin

            if(Cons_Counter[s]<Suff_Frames)

              if((Lane_ID_Flag[s] || Error_Bits_Lane_ID[s])) 
                Cons_Counter[s]<='b0;
              else
                Cons_Counter[s]<=Cons_Counter[s]+1;

           end 

         end 

         All_Lanes: begin
      
           for(s=0;s<NUM_LANES;s=s+1) begin

             if(Cons_Counter[s]<Suff_Frames)

              if((Lane_ID_Flag[s] || Error_Bits_Lane_ID[s])) 
                Cons_Counter[s]<='b0;
              else
                Cons_Counter[s]<=Cons_Counter[s]+1;

           end 

         end 

      endcase

   end   
      
   end else begin

     Iteration_Counter_LFSR <= Iteration_Counter_LFSR+1;
     if(Iteration_Counter_LFSR==Iteration_Count_LFSR-1)
        Test_Processing<='b0;

   end 

  end else begin 

  Iteration_Counter_Lane_ID <='b0 ;
  Iteration_Counter_LFSR    <='b0 ;
  Pattern_Counter           <='b0 ;  
  Test_Processing           <='b0 ; 
  for(s=0;s<NUM_LANES;s=s+1)
      Cons_Counter[s]<='b0;

  end 

end

//*****************************************************************************************//

endmodule
 
