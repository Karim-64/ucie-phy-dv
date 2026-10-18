import Universal_pkg ::* ; 


/*---------Description------------------//

this Module Reads D2D Messages from FIFO and Either deals with Priority Encoder 
to send the message on the SB Bus or Handles the Local RARs 
by dealing with configuration space and return Completions.

//---------------------------------------*/

module Decoder_SBTX #(parameter NC=32)
(
input  logic  CLK,RST_n                             ,     // LCLK and its domain reset

input  logic [1:0] state                            ,     // state of the LTSM to indicate the operation mode of the Decoder 

input logic Progress_Stop                           ,     //signal to stop decoding Messages from the D2D to prepare for TRAINERROR State

input  logic Empty_Flag                             ,     // SYNC FIFO Empty Flag 
input  logic [2*NC-1:0] Interface_Message           ,     // Data from the FIFO
input  logic Data_Marker_Out,Reg_Acc_Marker_Out     ,     // some Info bits that helps identifying the Incoming Message
input  logic Reg_Acc_Data_Marker_Out,Comp_Marker_Out,
input  logic rd_ack                                 ,
output logic RD_EN                                  ,     // SYNC FIFO Read Enable 
output logic Credit                                 ,     // control signal to release credit for Discarded Messages in RESET/SBINIT states 

input  logic UIRB_Done                              ,     // signals carrying the requested data from the UIRB for local RARs
input  logic [2*NC-1:0] UIRB_Resp                   ,      
output logic [BE_LENGTH-1:0] UIRB_BE                ,      
output logic UIRB_WR_EN,UIRB_RD_EN                  ,     // UIRB control signals
output logic [ADDR_LENGTH-1:0] UIRB_Addr            ,

input  logic D2D_Resend_Req                         ,     // signal from Priority Encoder inserted when PHY message is prioritized 
output logic [1:0] Sel                              ,     // Demux select to determine data goes to UIRB or CDC FIFO or D2D 
output logic Data_Marker,Comp_Marker,D2D_En         ,         
output logic [2*NC-1:0] Output_Message                    // output message to UIRB or CDC FIFO or Completion directed to D2D
);


//*********** function to format the Completion Header *******************//

function logic [2*NC-1:0] Format_Comp(
    logic [2*NC-1:0] input_value, 
    logic [2*NC-1:0] Resp_value, 
    OPCODES opcode, 
    logic UR_Comp
);
    // Extract different bit fields  
   logic [TAG_LENGTH-1:0] tag ;
   logic [BE_LENGTH-1:0]  be ;
   logic ep;
   logic cr, dp, cp;
   Comp_Status status;
   
   tag = input_value[tag_offset +: TAG_LENGTH];  
   be  = input_value[be_offset +: BE_LENGTH];  
   ep  = 1'b0;

    // Determine behavior based on 'opcode'
    case (opcode)
        Completion_Without_Data: begin 
            cr     = 1'b0;    
            status = SC;
            dp     = 1'b0;
        end 

        Completion_With_32b_Data: begin 
            cr     = 1'b0;    
            status = SC;
            dp     = ^Resp_value;
        end 

        Completion_With_64b_Data: begin
            if (UR_Comp) begin 
                cr     = 1'b1;    
                status = UR;
                dp     = ^input_value;
            end else begin 
                cr     = 1'b0;    
                status = SC;
                dp     = ^Resp_value;
            end 
        end
    endcase

    // Compute cp value
    cp  = ^{cr, 29'b0, status, 5'b0, tag, be, 8'b0, ep, opcode};

    // Reconstruct and return the formatted value
    return {dp,cp,cr,26'b0,status,5'b0,tag,be,8'b0,ep,opcode};

endfunction

//****************************************************************//

typedef enum logic [2:0] {
    IDLE                        = 3'b000,
    Unsupported_Request_Header  = 3'b001, 
    Unsupported_Request_Data    = 3'b010,
    D2D_Header                  = 3'b011,
    D2D_Data                    = 3'b100,
    Resp_Header                 = 3'b101,
    Resp_Data                   = 3'b110,
    Priority_Enc_Wait           = 3'b111              
} state_t;

state_t current_state, next_state;

always_ff @(posedge CLK or negedge RST_n) begin  
    if (!RST_n) 
        current_state <= IDLE;
    else 
        current_state <= next_state;
end


//*********** Internal Signals ****************//              
logic DST_ID_MSB,Remote_RAR_R,Remote_RAR;
logic [ADDR_LENGTH-1:0] Addr, Addr_R;
logic [2*NC-1:0] pack_reg, Resp_reg;
logic Local_RAR_R, Local_RAR_W, Local_RAR_W_R;
logic comp_type, comp_marker_R, data_marker_R,UIRB_Done_R;
//*********************************************//

//******************** Sequential Logic ************************//
always_ff @(posedge CLK or negedge RST_n) begin 
    if (!RST_n) begin
        pack_reg      <= 'b0;
        comp_marker_R <= 'b0;
        data_marker_R <= 'b0;
        comp_type     <= 'b0;
        Addr_R        <= 'b0;
        Local_RAR_W_R <= 'b0;
        Resp_reg      <= 'b0;
        Remote_RAR_R  <= 'b0;
        UIRB_Done_R   <= 'b0;   
    end else begin

        if (rd_ack && (current_state != D2D_Data)) begin
            pack_reg      <= Interface_Message;
            comp_marker_R <= Comp_Marker_Out;
            data_marker_R <= Data_Marker_Out;
            comp_type     <= Reg_Acc_Data_Marker_Out;
            Local_RAR_W_R <= Reg_Acc_Marker_Out & (Data_Marker_Out) & (DST_ID_MSB != Remote_Terminated_Request);
            Addr_R        <= Interface_Message[addr_offset +: ADDR_LENGTH];
            Remote_RAR_R  <= Reg_Acc_Marker_Out & (DST_ID_MSB == Remote_Terminated_Request);
        end 

        if (UIRB_Done) 
            Resp_reg <= UIRB_Resp;
        UIRB_Done_R   <= UIRB_Done; 

    end 
end
//******************** Combinational Assignments ************************//
assign DST_ID_MSB  = Interface_Message[dst_id_offset_64 + 2]; 
assign Addr        = Interface_Message[addr_offset +: ADDR_LENGTH]; 
assign Remote_RAR  = Reg_Acc_Marker_Out & (DST_ID_MSB == Remote_Terminated_Request);
assign Local_RAR_R = Reg_Acc_Marker_Out & (~Data_Marker_Out) & (DST_ID_MSB != Remote_Terminated_Request);
assign Local_RAR_W = Reg_Acc_Marker_Out & ( Data_Marker_Out) & (DST_ID_MSB != Remote_Terminated_Request);
//***************************************************//

always_comb begin                    //************ State Transition Logic ************//

    case (current_state)

        IDLE: begin

            next_state = (state == RESET_SBINIT || state == Other_State) ? (~Empty_Flag ? Unsupported_Request_Header : current_state) :
                         ((state == active & ~Progress_Stop) ?                          // stop writing Messages to the Async FIFO to prepare for the TRAINERROR/PHYRETRAIN State
                         (~Empty_Flag ? D2D_Header : current_state) : current_state); 
                            
        end

        Unsupported_Request_Header: 

        next_state = Unsupported_Request_Data;

        Unsupported_Request_Data: 

            next_state = IDLE;

        D2D_Header: 
            next_state = Local_RAR_R ? Resp_Header :(Local_RAR_W ? D2D_Data : Priority_Enc_Wait);

        Priority_Enc_Wait: 
            next_state = D2D_Resend_Req ? current_state :(data_marker_R ? D2D_Data : IDLE);

        D2D_Data: 
            next_state = Local_RAR_W_R ? Resp_Header : IDLE;

        Resp_Header: 
            next_state = UIRB_Done_R ? (Local_RAR_W_R ? IDLE : Resp_Data) : current_state;

        Resp_Data: 
            next_state = IDLE;

        default: 
            next_state = IDLE;

    endcase
end


always_comb begin                     //**********Outputs Transition**************//

//default values                      
UIRB_WR_EN=1'b0;
UIRB_RD_EN=1'b0;
UIRB_Addr='b0;
UIRB_BE ='b0;

RD_EN=1'b0;
Credit=1'b0;

Sel=2'b00;                  //{00-> UIRB_Data, 01--> D2D_Data, 10--> Completion Message} 
D2D_En = 1'b0;               
Output_Message='b0;
Data_Marker=1'b0;
Comp_Marker=1'b0;
  
  case(current_state)

  IDLE: begin 
    
    if(~Empty_Flag) begin 

     if(state == RESET_SBINIT || state == Other_State)
        
        RD_EN=1'b1;

      else if (state == active & ~Progress_Stop)

        RD_EN=1'b1;

      else 
      
        RD_EN=1'b0;
        
    end else 
        RD_EN=1'b0;

  end 

  Unsupported_Request_Header: begin

    Output_Message = Format_Comp(Interface_Message,'b0,Completion_With_64b_Data,1'b1);
    Sel    = (Remote_RAR) ? 2'b10 : 2'b00;
    Credit = (~Comp_Marker_Out)? 1'b1 : 1'b0;
    RD_EN  = Data_Marker_Out ? 1'b1 : 1'b0;

    end

   Unsupported_Request_Data: begin
   
   if(Remote_RAR_R)begin
   Sel=2'b10;
   Output_Message=pack_reg;
   end 
   
   end 
   
   D2D_Header: begin 

   if(Local_RAR_R) begin 

    UIRB_RD_EN=1'b1;
    UIRB_Addr=Addr;

   end else if (Local_RAR_W)

    RD_EN=1'b1;

   else begin 

     Sel=2'b01;
     D2D_En = 1'b1;
     Comp_Marker=Comp_Marker_Out;
     Data_Marker=Data_Marker_Out;
     Output_Message=Interface_Message; 

   end

   end 
   
   D2D_Data: begin 

   Output_Message=Interface_Message;
   Comp_Marker=Comp_Marker_Out;
   Data_Marker=Data_Marker_Out;

   if(Local_RAR_W_R) begin
        
        UIRB_WR_EN=1'b1;
        UIRB_Addr=Addr_R;
        UIRB_BE = pack_reg[be_offset +: BE_LENGTH];
       
    end else  Sel=2'b01;

   end 

   Resp_Header: begin

        if (UIRB_Done_R) begin    
          Sel = 2'b10;
          Output_Message = Local_RAR_W_R ? Format_Comp(pack_reg,'b0, Completion_Without_Data, 0) : 
                    (comp_type ? 
                        Format_Comp(pack_reg, UIRB_Resp, Completion_With_64b_Data, 0) : 
                        Format_Comp(pack_reg, UIRB_Resp, Completion_With_32b_Data, 0));
        end

    end

   Resp_Data : begin 

   Sel=2'b10;
   Output_Message=Resp_reg;

   end 

   Priority_Enc_Wait: begin 

     D2D_En = D2D_Resend_Req;
     Sel    = 2'b01;
     Comp_Marker=comp_marker_R;
     Data_Marker=data_marker_R;
     Output_Message=pack_reg;
     if(data_marker_R & ~D2D_Resend_Req)                                
      RD_EN=1'b1; 

   end 

   endcase 

end

endmodule





   


   
