`ifndef WR_CONTROL_SBTX_SCOREBOARD_SVH
`define WR_CONTROL_SBTX_SCOREBOARD_SVH

class wr_control_sbtx_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(wr_control_sbtx_scoreboard)
  uvm_analysis_imp#(wr_control_sbtx_sequence_item, wr_control_sbtx_scoreboard) sb_aimp;

  // Statistics tracking
  int match_count;
  int mismatch_count;
  int total_transactions;

  function new(string name = "wr_control_sbtx_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sb_aimp = new("sb_aimp", this);
    match_count = 0;
    mismatch_count = 0;
    total_transactions = 0;
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(wr_control_sbtx_sequence_item t);
    // Only perform checking when a write trigger occurs or an error is flagged
    if (t.FIFO_WR_exp || t.UIE_exp || t.Error_Handler_exp || t.FIFO_WR || t.UIE || t.Error_Handler
        || t.Data_Marker_exp || t.Reg_Acc_Marker_exp || t.Reg_Acc_Data_Marker_exp || t.Comp_Marker_exp || t.Req_Resp_Marker_exp
        || t.Data_Marker || t.Reg_Acc_Marker || t.Reg_Acc_Data_Marker || t.Comp_Marker || t.Req_Resp_Marker) begin
        total_transactions++;
        
        if (t.Interface_Message   != t.Interface_Message_exp ||
            t.FIFO_WR             != t.FIFO_WR_exp ||
            t.UIE                 != t.UIE_exp ||
            t.Error_Handler       != t.Error_Handler_exp ||
            t.Data_Marker         != t.Data_Marker_exp ||
            t.Reg_Acc_Marker      != t.Reg_Acc_Marker_exp ||
            t.Comp_Marker         != t.Comp_Marker_exp || 
            t.Reg_Acc_Data_Marker != t.Reg_Acc_Data_Marker_exp ||
            t.Req_Resp_Marker     !=t.Req_Resp_Marker_exp)begin
            
            `uvm_error("SB_MISMATCH", $sformatf("Mismatch in Transaction %0d! \n
              Expected -> Msg: %h, WR: %0b, UIE: %0b, Error Handler: %0b, DataMkr: %0b, CompMkr: %0b, RegAccMkr: %0b, RegAccDataMkr: %0b, ReqResMkr: %0b\n\
              Actual   -> Msg: %h, WR: %0b, UIE: %0b, Error Handler: %0b, DataMkr: %0b, CompMkr: %0b, RegAccMkr: %0b, RegAccDataMkr: %0b, ReqResMkr: %0b",
              total_transactions,
              t.Interface_Message_exp, t.FIFO_WR_exp, t.UIE_exp, t.Error_Handler_exp,
              t.Data_Marker_exp, t.Comp_Marker_exp, t.Reg_Acc_Marker_exp,t.Reg_Acc_Data_Marker_exp,t.Req_Resp_Marker_exp,
              t.Interface_Message, t.FIFO_WR, t.UIE, t.Error_Handler,
              t.Data_Marker, t.Comp_Marker, t.Reg_Acc_Marker,t.Reg_Acc_Data_Marker,t.Req_Resp_Marker))
              
            mismatch_count++;
        end else begin
            `uvm_info("SB_MATCH", $sformatf("Transaction %0d matched successfully.", total_transactions), UVM_HIGH)
            match_count++;
        end
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("SB_REPORT", "--------------------------------------------------", UVM_NONE)
    `uvm_info("SB_REPORT", $sformatf("Scoreboard Statistics:"), UVM_NONE)
    `uvm_info("SB_REPORT", $sformatf("Total Transactions Checked: %0d", total_transactions), UVM_NONE)
    `uvm_info("SB_REPORT", $sformatf("Matches: %0d", match_count), UVM_NONE)
    `uvm_info("SB_REPORT", $sformatf("Mismatches: %0d", mismatch_count), UVM_NONE)
    `uvm_info("SB_REPORT", "--------------------------------------------------", UVM_NONE)
    
    if (mismatch_count > 0) begin
        `uvm_error("SB_FAIL", "Scoreboard detected mismatches during simulation.")
    end
  endfunction
endclass

`endif // WR_CONTROL_SBTX_SCOREBOARD_SVH