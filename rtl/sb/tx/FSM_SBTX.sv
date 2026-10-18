
/*---------Description------------------//

this Module Manages the SBCLK Domain by generating control signals for several modules
to achieve some functions including :
1-sending the SBINIT Pattern 
2-sending the SBINIT_Out_of_Reset Message until being detected
3-Serializing D2D & Encoder Messages

//---------------------------------------*/


import Universal_pkg::*;

module TX_FSM_SBTX 
(
input  logic  CLK,RST_n        ,        //  SB clock&reset signals
input  logic [1:0] OPCODE      ,        //  opcode signal that indicate whether we are in the reset/sbinit states (pattern states) or active/training states (operational states)
input  logic  Empty_Flag       ,        //  empty flag of the fifo to load the serializer
input  logic  Patt_Recev       ,        //  signal from the pattern detector to mark that it received the pattern
input  logic  Send_Pattern     ,        //  signal from the Controller to mark starting the clock pattern cycle
input  logic  Data_Marker_Out  ,        //  control bit to indicate whether currently sent Message is with Data or not to generate Ser_Done
input  logic  alarm_64,alarm_32,        //  alarm signals of the Timer_64 and Timer_32
input  logic  alarm_1ms        ,        //  alarm, pattern alarm and start signals of the 1ms timer used with the clock pattern
input  logic  patt_alarm       ,
output logic  Start_1ms        ,
output logic  Ser_En           ,        //  enable for the serializer
output logic  Patt_Gen_En      ,        //  enable for the pattern generator to send the pattern
output logic  FIFO_RD          ,        //  read enable of the fifo to load data into the serializer
output logic  Patt_Cycle_Done  ,        //  signal sent to the Controller to mark that the 4 clock patterns sent after detecting the pattern on the Receiver are done
output logic  Out_Reset_Mess   ,        //  signal to load the serializer with the SBINIT_Out_of_Reset
output logic  Ser_Done                  //  signal to indicate that the Whole Message is fully Serialized
);

//******************Internal signals*******************************//

logic [$clog2(PATTERN_CYCLES)-1:0] count_pattern_times;  // counter to count the 4 times the pattern is sent after being detected on the Receiver
logic [$clog2(TIMER_CYCLES)-1:0]   count_timer_times;    // counter to count the 8 times we alternate between sending the pattern 1ms and holding for 1ms
logic Patt_Recev_reg;                                    // register to save the pattern received signal from the controller
logic alarm_64_reg,patt_alarm_reg,Data_Marker_Out_reg,Patt_Sent; 

//******************************************************************//

typedef enum logic [2:0] {
        IDLE                    =3'b000,
        Pattern_Operational     =3'b001,
        Pattern_Not_Operational =3'b010,
        Pattern_Detected        =3'b011,
        SERIALIZE               =3'b100
                         } state_t;

state_t current_state,next_state;


always_ff @(posedge CLK  or negedge RST_n) begin 
  
      if(!RST_n) begin
          current_state    <=IDLE;
      end else begin
          current_state    <=next_state;
      end
 end


always_comb begin             //**********states_transition************//

case (current_state)

IDLE : begin 

  case (OPCODE)
        
        RESET_SBINIT: begin 
             
              if (Patt_Sent) begin            

                if(~Empty_Flag || Send_Pattern)
                next_state=SERIALIZE;
                else 
                next_state=current_state;

              end else if(Send_Pattern)

              if(Patt_Recev || Patt_Recev_reg)
              next_state=Pattern_Detected;
              else 
              next_state=Pattern_Operational;

              else 

              next_state=current_state;

        end 

        default: begin

            if(!Empty_Flag)
              next_state = SERIALIZE;
            else 
              next_state = current_state;

        end 

   endcase

  end 

Pattern_Operational: begin 

   if(~alarm_1ms) begin 

     if(alarm_32) begin 

        if(Patt_Recev_reg) 
         next_state=Pattern_Detected;
        else 
         next_state=current_state;

     end else 

        next_state=current_state;

   end  else 

        next_state=Pattern_Not_Operational;
end 
   

Pattern_Not_Operational: begin 

 if(~alarm_1ms) begin 

   next_state=current_state;

 end else begin 
  
  if(count_timer_times==TIMER_CYCLES-1)
  next_state=IDLE;
  else
  next_state=Pattern_Operational;

 end 

end 

Pattern_Detected: begin 

   if(alarm_32 && count_pattern_times==PATTERN_CYCLES-1)
      next_state=IDLE;
   else 
      next_state=current_state;

end  

SERIALIZE : begin 

 if(alarm_32)
   next_state=IDLE;
 else 
   next_state=current_state;

end 

default : next_state=IDLE;

endcase 

end 


always_ff @(posedge CLK or negedge RST_n) begin        //**********counters_transition************//

if(!RST_n) begin 

  count_pattern_times<='b0;
  count_timer_times<='b0;

end else if (alarm_1ms) begin 

  if(count_timer_times == TIMER_CYCLES-1)
     count_timer_times<='b0;
  else 
     count_timer_times<=count_timer_times+1;

end else if (current_state== Pattern_Detected) begin 

  if(alarm_32) begin 

   if(count_pattern_times == PATTERN_CYCLES-1)
     count_pattern_times<='b0;
   else 
     count_pattern_times<=count_pattern_times+1; 

  end 

end 

end

always_comb begin           //**********outputs_transition************//

//Default Values 
Ser_En=1'b0;
FIFO_RD=1'b0;
Patt_Gen_En=1'b0;
Start_1ms=1'b0;
Patt_Cycle_Done=1'b0;
Ser_Done=1'b0;
Out_Reset_Mess=1'b0;
 

case (current_state)

IDLE: begin 

case (OPCODE)
        
        RESET_SBINIT: begin 
             
             if (Patt_Sent) begin             

              if(Send_Pattern)
                Out_Reset_Mess=1'b1;  
              else if(~Empty_Flag)
                FIFO_RD=1'b1;

             end 
  
        end  

        default: begin

            if(~Empty_Flag)
               FIFO_RD=1'b1;
            else 
               FIFO_RD=1'b0;
        end 
   endcase

end 


Pattern_Operational : begin 

Start_1ms=1'b1;

if(alarm_64_reg || alarm_64)
Patt_Gen_En=1'b0;
else if(patt_alarm || patt_alarm_reg)
Patt_Gen_En=1'b0;
else 
Patt_Gen_En=1'b1;
         
end


Pattern_Not_Operational : begin

Start_1ms=1'b1;
Patt_Gen_En=1'b0;
         
end


Pattern_Detected: begin 

if(alarm_64_reg || alarm_64)
Patt_Gen_En=1'b0;
else 
Patt_Gen_En=1'b1;

if(alarm_32 && count_pattern_times==PATTERN_CYCLES-1)
Patt_Cycle_Done=1'b1;

end 


SERIALIZE : begin 

if(alarm_64_reg || alarm_64)
Ser_En=1'b0;
else 
Ser_En=1'b1;

if(alarm_32) begin 
 
 if(~Data_Marker_Out_reg & ~Send_Pattern)
    Ser_Done=1'b1;

end 

end 
 
endcase 

end 

//**************Important Control Signals************************//

always_ff @(posedge CLK or negedge RST_n) begin 
    if (!RST_n) begin 
        Patt_Recev_reg       <= 'b0;
        alarm_64_reg         <= 'b0;
        patt_alarm_reg       <= 'b0;
        Data_Marker_Out_reg  <= 'b0;
        Patt_Sent            <= 'b0;
    end else begin  
        // Save control signals when asserted
        if (Patt_Cycle_Done)       Patt_Sent <= 1'b1;
        if (Patt_Recev)            Patt_Recev_reg <= 1'b1;
        if (alarm_64)              alarm_64_reg <= 1'b1;
        if (patt_alarm)            patt_alarm_reg <= 1'b1;
        if (FIFO_RD)               Data_Marker_Out_reg <=Data_Marker_Out;

        // Clear signals on specific conditions
        if (alarm_32) begin
            alarm_64_reg        <= 'b0;
            Data_Marker_Out_reg <= 'b0;
        end

        if (alarm_1ms) begin
            patt_alarm_reg <= 'b0;
        end

        // Reset Patt_Sent when leaving RESET_SBINIT state
        if (OPCODE != RESET_SBINIT) begin
            Patt_Sent <= 'b0;
        end
    end
end

//**********************************************************************//

endmodule 







