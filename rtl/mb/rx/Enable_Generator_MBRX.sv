import Universal_pkg ::*;

module Enable_Generator_MBRX #(parameter NUM_LANES=16,FRAME_LENGTH=8)
(
input  logic CLK,RST_n                               ,  //MB CLK
input  LTSM_states LTSM_State                        ,
input  logic [WIDTH_DEGRADE_LENGTH-1:0] Width_Degrade,  //only half the lanes are used (011-> 15:0,001->7:0 , 010->15:8)
input  logic Valid                                   ,  //valid lane 
input  logic Comparison_Done                         ,  //indication of Data_Comparator finished comparison
input  logic Valid_Frame_Error                       ,  //Control Signals that mark end of deserializing a Frame or End of Valid Test
input  logic Detec_succ                              ,
input  logic Test_Resp                               ,  //indication that the SB sent the ready response for the Remote die so that the Transmitter can start the test                     
output logic Vchk_EN                                 ,  //Control Signals for Various Modules across MB_RX
output logic Descr_EN                                ,
output logic Deserializer_EN1, Deserializer_EN2      ,
output logic Data_Comparator_EN                      ,
output logic Valid_Detected                          ,
output logic Comparison_Type                         , 
output logic LFSR_SEL
);


//************** Internal Signals ********************//

bit Chunk_Marker;   
LTSM_states LTSM_State_old; // to de-assert the chunk marker                                 
bit Valid_Delay;                                     
logic Test_Resp_latched;

logic Test_End_Detected;

//**************************************************//


//************************ Edge Detector for detecting a new frame ****************//

always_ff @(posedge CLK or negedge RST_n) begin

  if(!RST_n) begin

  Valid_Delay <= 'b0;

  end else begin 

  Valid_Delay <= Valid;

  end  
end

assign Valid_Detected = (~Valid_Delay) & Valid;

//******************************************************//

//*************** Latch the Test_Resp once it is asserted ************//

always_ff @(posedge CLK or negedge RST_n) begin

    if (!RST_n) begin
        Test_Resp_latched <= 1'b0;
    end else if (Test_Resp) begin
        Test_Resp_latched <= 1'b1;
    end else if (Comparison_Done || Valid_Frame_Error || Detec_succ) begin
        Test_Resp_latched <= 1'b0;
    end

end

//********************************************************************//


//***********************Chunk Detector*******************************// 
always_ff @(posedge CLK or negedge RST_n) begin 

    if(!RST_n)
      LTSM_State_old  <= _RESET;
    else  
      LTSM_State_old  <= LTSM_State;

end

always_ff @(posedge CLK or negedge RST_n) begin 

    if(!RST_n)
      Chunk_Marker<='b0; 
    else if (Valid_Frame_Error || Detec_succ || Comparison_Done || (LTSM_State != LTSM_State_old)) 
      Chunk_Marker<='b0; 
    else if(Valid_Detected)
      Chunk_Marker<='b1;

end 

assign Test_End_Detected = Valid_Frame_Error || Detec_succ;

//**********************************************************************//


always_comb begin          // Vchk_EN generator

 case (LTSM_State)
        _ACTIVE:  Vchk_EN = (((Valid_Detected) || (Chunk_Marker)) && ~(Test_End_Detected)) ? 1'b1 : 1'b0;
        default: Vchk_EN = (((Valid_Detected) || (Chunk_Marker)) && ~(Test_End_Detected)) & (Test_Resp_latched) ? 1'b1 : 1'b0;
    endcase

end 


always_comb begin          // deserializers are only used in _ACTIVE state

 if(LTSM_State==_ACTIVE) begin

    Deserializer_EN1 = ((Valid_Detected) || (Chunk_Marker)) ? (Width_Degrade != 2) : 1'b0;

    Deserializer_EN2 = ((Valid_Detected) || (Chunk_Marker)) ? (Width_Degrade != 1) : 1'b0;

 end else begin 

    Deserializer_EN1 = 1'b0;

    Deserializer_EN2 = 1'b0;

 end 

end 


always_comb begin             // Data_Comparator_EN generator

     case (LTSM_State)
        _MBINIT_REVERSALMB, _MBINIT_REPAIRMB, _MBTRAIN_DATAVREF, 
        _MBTRAIN_DATATRAINCENTER1, _MBTRAIN_DATATRAINVREF, _MBTRAIN_RXDESKEW, 
        _MBTRAIN_DATATRAINCENTER2, _MBTRAIN_LINKSPEED:
            Data_Comparator_EN =(((Valid_Detected) || (Chunk_Marker)) && ~(Comparison_Done)) & (Test_Resp_latched) ? 1'b1 : 1'b0;
        default:
            Data_Comparator_EN = 1'b0;
    endcase
    
end


always_comb begin               // Descrambler_EN generator

  case (LTSM_State)

   _MBTRAIN_DATAVREF,_MBTRAIN_DATATRAINCENTER1, _MBTRAIN_DATATRAINVREF, _MBTRAIN_RXDESKEW, 
   _MBTRAIN_DATATRAINCENTER2, _MBTRAIN_LINKSPEED: begin 
   Descr_EN = (((Valid_Detected) || (Chunk_Marker)) && ~(Comparison_Done)) & (Test_Resp_latched) ? 1'b1 : 1'b0;
   LFSR_SEL = 1'b1;
   end 

   _ACTIVE: begin 
  
   Descr_EN = ((Valid_Detected) || (Chunk_Marker)) && ~(Test_End_Detected) ? 1'b1:1'b0;
   LFSR_SEL = 1'b0;

   end 

   default : begin 
   Descr_EN = 1'b0;
   LFSR_SEL = 1'b0;

   end 
   
  endcase

end 

assign Comparison_Type= ((LTSM_State== _MBINIT_REVERSALMB || LTSM_State== _MBINIT_REPAIRMB))? 1'b1:1'b0;

endmodule

