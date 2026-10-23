module WR_Control_SBTX_ref #(parameter NC=32)
(
input  logic CLK,RST_n                      , // LCLK and its Domain reset

input  logic lp_cfg_vld                     , // interface signal that indicate new data is available from the adapter
input  logic [NC-1:0] lp_cfg                , // Data from the adapter

output logic [2*NC-1:0] Interface_Message_exp   , // 2 phases from the message  (Data or Header)
output logic Data_Marker_exp,Reg_Acc_Marker_exp     , // marker to mark that the Message is with Data/is Register Access Request
output logic Reg_Acc_Data_Marker_exp,Comp_Marker_exp, // marker to mark that the RAR is with Data/is completion Message
output logic Req_Resp_Marker_exp                , // marker to mark that the Message is Request or Response
output logic Error_Handler_exp                  ,
output logic FIFO_WR_exp                        , // write enable for the FIFO to write the 2 phases

output logic UIE_exp                              // uncorrectable internal error is detected 
);

typedef enum  {Header_Phase0,Header_Phase1,Data_Phase0,Data_Phase1} state_t;
state_t cs,ns;
logic[NC-1:0] header0,data0;
logic[2*NC-1:0] full_header,full_data;
bit dp_calc,dp_received,cp_calc,cp_received;

bit header_available,data_available;

//MPM and Priority Packets not supported
typedef enum logic [4:0] {
  MEM_RD_32B           = 5'b00000, // 32b Memory Read
  MEM_WR_32B           = 5'b00001, // 32b Memory Write
  //DMS_REG_RD_32B       = 5'b00010, // 32b DMS Register Read
  //DMS_REG_WR_32B       = 5'b00011, // 32b DMS Register Write
  CFG_RD_32B           = 5'b00100, // 32b Configuration Read
  CFG_WR_32B           = 5'b00101, // 32b Configuration Write
  
  MEM_RD_64B           = 5'b01000, // 64b Memory Read
  MEM_WR_64B           = 5'b01001, // 64b Memory Write
  //DMS_REG_RD_64B       = 5'b01010, // 64b DMS Register Read
  //       = 5'b01011, // 64b DMS Register Write
  CFG_RD_64B           = 5'b01100, // 64b Configuration Read
  CFG_WR_64B           = 5'b01101, // 64b Configuration Write
  
  CMPL_NO_DATA         = 5'b10000, // Completion without Data
  CMPL_WITH_32B_DATA   = 5'b10001, // Completion with 32b Data
  MSG_NO_DATA          = 5'b10010, // Message without Data
  //MGMT_MSG_NO_DATA     = 5'b10111, // Management Port Messages without Data
  
  //MGMT_MSG_WITH_DATA   = 5'b11000, // Management Port Message with Data
  CMPL_WITH_64B_DATA   = 5'b11001, // Completion with 64b Data
  MSG_WITH_64B_DATA    = 5'b11011 // Message with 64b Data
  
 // PRIORITY_PKT_1E      = 5'b11110, // Priority Packet
 // PRIORITY_PKT_1F      = 5'b11111  // Priority Packet
} sideband_opcode_e;

sideband_opcode_e opcode,pre_opcode;

//state_memory
always @(posedge CLK or negedge RST_n) begin
    if (~RST_n) begin
        cs<=Header_Phase0;
    end else begin
        cs<=ns;
    end
end

//ns logic
always @(*) begin
    ns=cs;
    case (cs)
        Header_Phase0:begin
           // if(lp_cfg_vld || data_available)begin
            if(lp_cfg_vld)begin
                ns=Header_Phase1;
            end

        end
        Header_Phase1:begin
            if (lp_cfg_vld) begin
                if (opcode inside {MEM_WR_32B,CFG_WR_32B,MEM_WR_64B,CFG_WR_64B,
                        CMPL_WITH_32B_DATA,CMPL_WITH_64B_DATA,MSG_WITH_64B_DATA}) begin
                    ns=Data_Phase0;
                end else begin
                    ns=Header_Phase0;
                end
            end
        end
        Data_Phase0:begin
            if (lp_cfg_vld) begin
                ns=Data_Phase1;
            end
        end
        Data_Phase1:begin
            if (lp_cfg_vld) begin
                ns=Header_Phase0;
            end
        end
        default: begin
            ns=cs;
        end
    endcase
end

//output logic
always @(posedge CLK or negedge RST_n) begin
    if (~RST_n) begin
        Interface_Message_exp<=0;
        Data_Marker_exp<=0;
        Reg_Acc_Marker_exp<=0;
        Reg_Acc_Data_Marker_exp<=0;
        Comp_Marker_exp<=0;
        Req_Resp_Marker_exp <= 0;
        Error_Handler_exp<=0;
        FIFO_WR_exp<=0;
        UIE_exp<=0;

        header_available<=0;
        data_available<=0;

    end else begin
        Data_Marker_exp<=0;
        Reg_Acc_Marker_exp<=0;
        Reg_Acc_Data_Marker_exp<=0;
        Comp_Marker_exp<=0;
        Req_Resp_Marker_exp <= 0;
        Error_Handler_exp<=0;
        FIFO_WR_exp<=0;
        if(~data_available) UIE_exp<=0;
        //Check header_available first (at the end of Header_Phase1 for 2-phase, or end of Data_Phase1 for 4-phase),
        // and on the very next cycle when header_available is 0 and data_available is 1, output full_data regardless of ns
        if (ns == Header_Phase0 && header_available) begin
            Interface_Message_exp<=full_header;
            FIFO_WR_exp<=1;

            if(pre_opcode inside {MEM_WR_32B,CFG_WR_32B,MEM_WR_64B,CFG_WR_64B,
                CMPL_WITH_32B_DATA,CMPL_WITH_64B_DATA,MSG_WITH_64B_DATA})begin
                Data_Marker_exp<=1;
            end
            if (pre_opcode inside {MEM_WR_32B,CFG_WR_32B,MEM_WR_64B,CFG_WR_64B,
                MEM_RD_32B,CFG_RD_32B,MEM_RD_64B,CFG_RD_64B}) begin
                Reg_Acc_Marker_exp<=1;
            end

            //Used by decoder to remember whether the read request is 64-bit rather than 32-bit
            if(pre_opcode inside {MEM_RD_64B,CFG_RD_64B}) begin
                Reg_Acc_Data_Marker_exp<=1;
            end

            if (pre_opcode inside {CMPL_NO_DATA,CMPL_WITH_32B_DATA,CMPL_WITH_64B_DATA}) begin
                Comp_Marker_exp<=1;
            end

            //Messages with req/res should have priority on RARs
            if (  (pre_opcode==MSG_NO_DATA && 
                  (full_header[21:14] inside {[8'h01:8'h09]} || (full_header[21:18] inside {[4'h8:4'hE]} && full_header[17:14] inside {4'h5,4'hA}) ) )
               || (pre_opcode==MSG_WITH_64B_DATA && 
                  ( (full_header[21:18] inside {[4'h8:4'hB]} && full_header[17:14] inside {4'h5,4'hA}) ||
                  full_header[21:14] inside {[1:2]}) ) ) begin

                Req_Resp_Marker_exp<=1;
            end
                
            if(dp_calc != dp_received || cp_calc != cp_received)begin
                UIE_exp<=1;
                if(~(pre_opcode inside {CMPL_NO_DATA,CMPL_WITH_32B_DATA,CMPL_WITH_64B_DATA}))begin
                    Error_Handler_exp<=1;
                end
            end
            
            header_available<=0;
        end else if (data_available) begin
            Interface_Message_exp<=full_data;
            FIFO_WR_exp<=1;
            data_available<=0;
        end

    end
end

always @(*) begin
        case (cs)
            Header_Phase0:begin
                if (lp_cfg_vld) begin
                    header0=lp_cfg;
                    opcode=sideband_opcode_e'(lp_cfg[4:0]);                   

                end
            end 
            Header_Phase1:begin
                if (lp_cfg_vld) begin
                    full_header={lp_cfg,header0};
                    dp_received=lp_cfg[31];
                    cp_received=lp_cfg[30];
                    cp_calc=^full_header[61:0];
                    if (opcode inside {MEM_RD_32B, CFG_RD_32B, MEM_RD_64B
                        , CFG_RD_64B,CMPL_NO_DATA,MSG_NO_DATA}) begin
                        dp_calc=1'b0;
                    end
                    header_available=1;
                    pre_opcode=opcode;
                end
            end
            Data_Phase0:begin
                if (lp_cfg_vld) begin
                    data0=lp_cfg;
                end
            end
            Data_Phase1:begin
                if (lp_cfg_vld) begin
                    full_data={lp_cfg,data0};
                    dp_calc=^full_data;
                    data_available=1;
                end
            end
        endcase
end

endmodule