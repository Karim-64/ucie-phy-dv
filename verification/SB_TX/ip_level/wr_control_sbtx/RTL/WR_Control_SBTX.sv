
/*---------Description------------------ // 

this Module :
1-Receives phases of a Message from D2D and checks for any Parity Errors.
2-generates UIE to indicate a detected Parity Error that is furtherly used by the RDI Module
3-generates Markers by means of Comparison Circuits to be used by all necessary modules accross SB_TX
4-gather Header Phases & Data Phases and write them in FIFO if not Errord.

//---------------------------------------*/

import Universal_pkg ::* ;

module WR_Control_SBTX #(parameter NC=32)
(
input logic CLK,RST_n , // LCLK and its Domain reset

input logic lp_cfg_vld , // interface signal that indicate new data is available from the adapter
input logic [NC-1:0] lp_cfg , // Data from the adapter

output logic [2*NC-1:0] Interface_Message , // 2 phases from the message  (Data or Header)
output logic Data_Marker,Reg_Acc_Marker , // marker to mark that the Message is with Data/is Register Access Request
output logic Reg_Acc_Data_Marker,Comp_Marker, // marker to mark that the RAR is with Data/is completion Message
output logic Req_Resp_Marker , // marker to mark that the Message is Request or Response
output logic Error_Handler ,
output logic FIFO_WR , // write enable for the FIFO to write the 2 phases

output logic UIE // uncorrectable internal error is detected
);

//********** Internal Signals ***********//

bit [NC-1:0] pack_reg_0,pack_reg_1,pack_reg_2,pack_reg_3;
bit CP_calc,DP_calc;
bit CP_act,DP_act,DP_act_c;
logic Data_Message,UIE_R;
OPCODES OPCODE;
msgcode_e MSGCODE;

//*************************************//

typedef enum logic [1:0] {
  Phase_0 = 2'b00,
  Phase_1 = 2'b01,
  Phase_2 = 2'b10,
  Phase_3 = 2'b11
} state_t;

state_t current_state,next_state;

always_ff @(posedge CLK or negedge RST_n) begin

  if(!RST_n) begin
    current_state <=Phase_0;
  end else begin
  current_state <=next_state;
end
end

//*****************Intermediate Variables*******************//

always_ff @(posedge CLK or negedge RST_n) begin

  if (!RST_n) begin

    pack_reg_0 <= 'b0;
    pack_reg_1 <= 'b0;
    pack_reg_2 <= 'b0;
    pack_reg_3 <= 'b0;
    OPCODE <= OPCODES'(0);
    DP_act <= 'b0;
    MSGCODE <= msgcode_e'(0);
    Data_Message<='b0;
    UIE_R<='b0;

  end else begin

  case (current_state)

    Phase_0: begin
      if (lp_cfg_vld) begin
        pack_reg_0 <= lp_cfg;
        OPCODE <= OPCODES'(lp_cfg[opcode_offset +: OPCODE_LENGTH]);
        MSGCODE <= msgcode_e'(lp_cfg[msgcode_offset +: MSGCODE_LENGTH]);
      end
      Data_Message<=1'b0;
      UIE_R<='b0;
    end

    Phase_1: if (lp_cfg_vld) begin
      pack_reg_1 <= lp_cfg;
      DP_act <= lp_cfg[dp_offset_32];
      if(CP_calc != CP_act)
      UIE_R<='b1;
    end

    Phase_2: if (lp_cfg_vld) begin
      pack_reg_2 <= lp_cfg;
    end

    Phase_3: if (lp_cfg_vld) begin
      pack_reg_3 <= lp_cfg;
      Data_Message<=1'b1;
      if(DP_calc != DP_act)
      UIE_R<='b1;
    end

  endcase
end
end

//*********************************************************//

always_comb begin // **********states_transition************//

  case(current_state)

    Phase_0: begin

      if(lp_cfg_vld)
      next_state=Phase_1;
      else
      next_state=current_state;

    end

    Phase_1: begin

      if(lp_cfg_vld) begin

        case(OPCODE)

          Memory_Write_32b, Configuration_Write_32b,
          Memory_Write_64b, Configuration_Write_64b,
          Completion_With_32b_Data, Completion_With_64b_Data,
          Message_With_64b_Data: next_state = Phase_2; // Valid 4-phase Message With Data

          default: next_state = Phase_0; // Valid 2-phase or Reserved/Illegal Opcode

        endcase

      end else begin

      next_state=current_state;

    end

  end

  Phase_2: begin

    if(lp_cfg_vld)
    next_state=Phase_3;
    else
    next_state=current_state;

  end

  Phase_3: begin

    if(lp_cfg_vld) begin
      next_state=Phase_0;
    end else
    next_state=current_state;

  end

endcase

end

always_ff @(posedge CLK or negedge RST_n) begin // **********Outputs_transition************//

  if(!RST_n) begin

    UIE<=1'b0;
    FIFO_WR <=1'b0;
    Interface_Message <='b0;
    Data_Marker <=1'b0;
    Reg_Acc_Marker <=1'b0;
    Reg_Acc_Data_Marker<=1'b0; // {0 --> 32b , 1 --> 64b}
    Comp_Marker <=1'b0;
    Req_Resp_Marker <=1'b0;
    Error_Handler <=1'b0;

  end else begin

  //default values
  UIE<=1'b0;
  FIFO_WR <=1'b0;
  Interface_Message <='b0;
  Data_Marker <=1'b0;
  Reg_Acc_Marker <=1'b0;
  Reg_Acc_Data_Marker<=1'b0;
  Comp_Marker <=1'b0;
  Req_Resp_Marker <=1'b0;
  Error_Handler <=1'b0;

  case(current_state)

    Phase_0 : begin

      if(Data_Message && !UIE_R) begin

        FIFO_WR <= 1'b1;
        Interface_Message <= {pack_reg_3, pack_reg_2};

      end

    end

    Phase_1: begin

      if(lp_cfg_vld) begin

        case(OPCODE)

          Memory_Read_32b,Configuration_Read_32b,Memory_Read_64b,Configuration_Read_64b,
          Completion_Without_Data,Message_Without_Data: begin

            if((CP_calc != CP_act) || DP_act_c != 1'b0) begin

              UIE <= 1'b1;
              Error_Handler <= ~(OPCODE == Completion_Without_Data) ? 1'b1 : 1'b0;

            end else begin

              case (OPCODE)

                Memory_Read_32b,Configuration_Read_32b: begin
                  Reg_Acc_Marker <= 1'b1;
                  Reg_Acc_Data_Marker <= 1'b0;
                end

                Memory_Read_64b,Configuration_Read_64b: begin
                  Reg_Acc_Marker <= 1'b1;
                  Reg_Acc_Data_Marker <= 1'b1;
                end

                Completion_Without_Data: begin
                  Comp_Marker <= 1'b1;
                end

                Message_Without_Data: begin
                  case (MSGCODE)
                    lnkmgmt_req, lnkmgmt_resp,
                    lnkmgmnt_adp0_req, lnkmgmt_adp0_rsp,
                    lnkmgmnt_adp1_req, lnkmgmt_adp1_rsp,
                    ParityFeature_Req, ParityFeature,
                    req_tests, resp_tests,
                    req_sb, resp_sb,
                    req_MBINIT, resp_MBINIT,
                    req_MBTRAIN, resp_MBTRAIN,
                    PHYRETRAIN_req, PHYRETRAIN_resp,
                    RECAL_req, RECAL_resp,
                    TRAINERROR_req, TRAINERROR_resp: Req_Resp_Marker <= 1'b1;
                    default: Req_Resp_Marker <= 1'b0;
                  endcase
                end

              endcase

              Interface_Message <= {lp_cfg, pack_reg_0};
              FIFO_WR <= 1'b1;

            end

          end

          Memory_Write_32b, Configuration_Write_32b,
          Memory_Write_64b, Configuration_Write_64b,
          Completion_With_32b_Data, Completion_With_64b_Data,
          Message_With_64b_Data: begin
            // 4-phase packet: outputs evaluated in Phase_3 after Data phases arrive
          end

          default: begin
            // Reserved / illegal opcode: drop packet and flag UIE + Error_Handler
            UIE           <= 1'b1;
            Error_Handler <= 1'b1;
          end

        endcase

      end

    end

    Phase_3: begin

      if(lp_cfg_vld) begin

        if((DP_calc != DP_act) || UIE_R) begin

          UIE <= 1'b1;
          Error_Handler <= ~(OPCODE == Completion_With_32b_Data || OPCODE == Completion_With_64b_Data) ? 1'b1 : 1'b0;

        end else begin

          Interface_Message <= {pack_reg_1, pack_reg_0};
          FIFO_WR <= 1'b1;
          Data_Marker <= 1'b1; // Mark the Header that represent a Message with Data

          case (OPCODE)

            Memory_Write_32b, Configuration_Write_32b,
            Memory_Write_64b, Configuration_Write_64b: begin
              Reg_Acc_Marker <= 1'b1;
            end

            Completion_With_32b_Data, Completion_With_64b_Data: begin
              Comp_Marker <= 1'b1;
            end

          endcase

        end

      end

    end

  endcase

end

end

assign CP_calc = ^{(lp_cfg & ~(32'h1 << cp_offset_32) & ~(32'h1 << dp_offset_32)),pack_reg_0};
assign CP_act =lp_cfg[cp_offset_32];
assign DP_act_c =lp_cfg[dp_offset_32];
assign DP_calc=^{lp_cfg,pack_reg_2};

endmodule
