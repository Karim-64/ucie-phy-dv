`ifndef WR_CONTROL_SBTX_SCOREBOARD_SVH
`define WR_CONTROL_SBTX_SCOREBOARD_SVH

class wr_control_sbtx_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(wr_control_sbtx_scoreboard)
  uvm_analysis_export   #(wr_control_sbtx_sequence_item)  sb_aexp;
  uvm_tlm_analysis_fifo #(wr_control_sbtx_sequence_item)  sb_fifo;

  // counters
  int pass_count;
  int fail_count;
  int total_transactions;

  wr_control_sbtx_sequence_item item;
  wr_control_sbtx_sequence_item exp_out;

  // ref_model variables 
  typedef enum bit [1:0]{ 
    HP0,
    HP1, 
    DP0, 
    DP1
  }state_t;

  typedef enum bit [2:0] {
    RAR,
    COMP,
    MSG,
    REQ_RESP,
    INVALID
  }packet_type_e;

  state_t                ns, cs;
  packet_type_e          packet_type;
  bit                    with_data;
  bit                    rar_64;
  bit                    is_req_resp;
  bit                    cp_err;
  bit                    dp_err;
  bit                    opcode_err;
  bit                    expected_dp;

  sb_opcode_e            opcode;
  req_resp_msgcode_e     req_resp_code;
  non_req_resp_msgcode_e non_req_resp_code;

  logic [NC-1:0]         header_rec0;
  logic [NC-1:0]         header_rec1;
  logic [NC-1:0]         data0_rec;
  logic [NC-1:0]         data1_rec;

  logic [NC*2-1:0]       header_payload;
  logic [NC*2-1:0]       data_payload;

  wr_control_sbtx_sequence_item exp_q[$];

  function new(string name = "wr_control_sbtx_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sb_aexp = new("sb_aexp", this);
    sb_fifo = new("sb_fifo", this);
    pass_count = 0;
    fail_count = 0;
    total_transactions = 0;
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    sb_aexp.connect(sb_fifo.analysis_export); 
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);

    exp_out = create_idle_item();
    cs      = HP0;
    ns      = HP0;

    // Discard first item (sampled before first driver NBA takes effect)
    sb_fifo.get(item);

    forever begin
      sb_fifo.get(item);

      if (!item.RST_n) begin
        // Async reset clears DUT outputs immediately; reset prediction before checking
        ref_model(item);
        check_results(item);
      end else begin
        // Compare-first, then-step: check Cycle k outputs against Cycle k-1 prediction
        check_results(item);
        ref_model(item);
      end
    end
  endtask

  // Helper: create an all-zero (idle) expected item
  function wr_control_sbtx_sequence_item create_idle_item();
    wr_control_sbtx_sequence_item idle;
    idle = wr_control_sbtx_sequence_item#(NC)::type_id::create("idle");
    idle.Interface_Message   = '0;
    idle.FIFO_WR             = 1'b0;
    idle.Data_Marker         = 1'b0;
    idle.Reg_Acc_Marker      = 1'b0;
    idle.Reg_Acc_Data_Marker = 1'b0;
    idle.Comp_Marker         = 1'b0;
    idle.Req_Resp_Marker     = 1'b0;
    idle.UIE                 = 1'b0;
    idle.Error_Handler       = 1'b0;
    return idle;
  endfunction

  // Helper: schedule a validated 64-bit Header output cycle
  function void push_header_item();
    wr_control_sbtx_sequence_item hdr_item = create_idle_item();
    hdr_item.Interface_Message   = header_payload;
    hdr_item.FIFO_WR             = 1'b1;
    hdr_item.Data_Marker         = with_data;
    hdr_item.Reg_Acc_Marker      = (packet_type == RAR);
    hdr_item.Reg_Acc_Data_Marker = (packet_type == RAR) ? rar_64 : 1'b0;
    hdr_item.Comp_Marker         = (packet_type == COMP);
    hdr_item.Req_Resp_Marker     = (packet_type == MSG) ? is_req_resp : 1'b0;
    exp_q.push_back(hdr_item);
  endfunction

  // Helper: schedule a validated 64-bit Data payload output cycle
  function void push_data_item();
    wr_control_sbtx_sequence_item data_item = create_idle_item();
    data_item.Interface_Message = data_payload;
    data_item.FIFO_WR           = 1'b1;
    exp_q.push_back(data_item);
  endfunction

  // Helper: schedule a 1-cycle blocked error pulse (Ideal Spec contract)
  function void push_error_item();
    wr_control_sbtx_sequence_item err_item = create_idle_item();
    err_item.UIE           = 1'b1;
    err_item.Error_Handler = (packet_type != COMP);
    exp_q.push_back(err_item);
  endfunction

  function void ref_model(wr_control_sbtx_sequence_item t);
    if (!t.RST_n) begin
      cs      = HP0;
      ns      = HP0;
      exp_q.delete();
      exp_out = create_idle_item();
      return;
    end

    // next state logic 
    cs = ns;
    case (cs)
      HP0: begin
        if (t.lp_cfg_vld) begin
          header_rec0 = t.lp_cfg;
          opcode      = sb_opcode_e'(header_rec0[4:0]);

          opcode_err  = 1'b0;
          cp_err      = 1'b0;
          dp_err      = 1'b0;
          rar_64      = 1'b0;
          is_req_resp = 1'b0;
          with_data   = 1'b0;

          // Req_Resp_Marker | Data_Marker
          if (opcode inside {msg_packets}) begin
            packet_type = MSG;
            with_data   = (opcode == SB_MSG_WITH_64B_DATA);

            if (opcode == SB_MSG_NO_DATA) begin
              if ($cast(req_resp_code, header_rec0[21:14]))
                is_req_resp = 1'b1;
              else if ($cast(non_req_resp_code, header_rec0[21:14]))
                is_req_resp = 1'b0;
              else
                opcode_err  = 1'b1;
            end
            else begin
              // Message_With_64b_Data never carries a Req_Resp message; RTL ignores MSGCODE here
              is_req_resp = 1'b0;
            end
          end
          // RAR_Marker | Data_Marker
          else if (opcode inside {rar_packets}) begin
            packet_type = RAR;
            with_data   = (opcode inside {SB_MEM_WR_32B, SB_CFG_WR_32B, SB_MEM_WR_64B, SB_CFG_WR_64B});
            // Only 64-bit RAR Reads assert Reg_Acc_Data_Marker; RAR Writes assert Reg_Acc_Marker only
            rar_64      = (opcode inside {SB_MEM_RD_64B, SB_CFG_RD_64B});
          end

          // Comp_Marker | Data_Marker 
          else if (opcode inside {comp_packets}) begin
            packet_type = COMP;
            with_data   = (opcode inside {SB_CMPL_WITH_32B_DATA, SB_CMPL_WITH_64B_DATA});
          end
          
          // Reserved 
          else begin  
          packet_type = INVALID;
          opcode_err  = 1'b1;
          end
          ns = HP1;
        end 
        else ns = HP0;
      end

      HP1: begin
        if (t.lp_cfg_vld) begin
          header_rec1    = t.lp_cfg;
          header_payload = {header_rec1, header_rec0};

          // Control Parity (bit 30 of Phase 1) over lower 62 header bits
          cp_err         = (header_rec1[30] != ^header_payload[61:0]);
          expected_dp    = header_rec1[31];

          if (opcode_err) begin
            push_error_item();
            ns = HP0;
          end else if (!with_data) begin
            // 2-phase packet: dp = 0
            dp_err = (expected_dp != 1'b0);
            if (cp_err || dp_err)
              push_error_item();
            else
              push_header_item();
            ns = HP0;
          end 
          else 
            // 4-phase packet
            ns = DP0;
        end 
        else ns = HP1;
      end

      DP0: begin
        if (t.lp_cfg_vld) begin 
          data0_rec = t.lp_cfg;
          ns = DP1;
        end
        else ns = DP0;
      end
      DP1: begin
        if (t.lp_cfg_vld) begin 
          data_payload = {t.lp_cfg, data0_rec};
          
          // data parity check
          dp_err = (expected_dp != ^data_payload[63:0]);
          if (dp_err || cp_err) begin
            push_error_item();
          end else begin
            push_header_item();
            push_data_item();
          end
          ns = HP0;
        end
        else ns = DP1;
      end
    endcase

    if (exp_q.size() > 0)
      exp_out = exp_q.pop_front();
    else
      exp_out = create_idle_item();
  endfunction

  function void check_results(wr_control_sbtx_sequence_item t);
    total_transactions++;

    if (t.Interface_Message   !== exp_out.Interface_Message   ||
        t.FIFO_WR             !== exp_out.FIFO_WR             ||
        t.UIE                 !== exp_out.UIE                 ||
        t.Error_Handler       !== exp_out.Error_Handler       ||
        t.Data_Marker         !== exp_out.Data_Marker         ||
        t.Reg_Acc_Marker      !== exp_out.Reg_Acc_Marker      ||
        t.Reg_Acc_Data_Marker !== exp_out.Reg_Acc_Data_Marker ||
        t.Comp_Marker         !== exp_out.Comp_Marker         ||
        t.Req_Resp_Marker     !== exp_out.Req_Resp_Marker) begin
      fail_count++;
      `uvm_error("SB_MISMATCH", $sformatf(
        "Cycle %0d mismatch (RST_n=%0b lp_cfg_vld=%0b lp_cfg=0x%08h)\n  Expected -> Msg: 0x%016h, WR: %0b, UIE: %0b, ErrHdlr: %0b, DataMkr: %0b, RAR: %0b, RAR64: %0b, Comp: %0b, ReqResp: %0b\n  Actual   -> Msg: 0x%016h, WR: %0b, UIE: %0b, ErrHdlr: %0b, DataMkr: %0b, RAR: %0b, RAR64: %0b, Comp: %0b, ReqResp: %0b",
        total_transactions, t.RST_n, t.lp_cfg_vld, t.lp_cfg,
        exp_out.Interface_Message, exp_out.FIFO_WR, exp_out.UIE, exp_out.Error_Handler,
        exp_out.Data_Marker, exp_out.Reg_Acc_Marker, exp_out.Reg_Acc_Data_Marker,
        exp_out.Comp_Marker, exp_out.Req_Resp_Marker,
        t.Interface_Message, t.FIFO_WR, t.UIE, t.Error_Handler,
        t.Data_Marker, t.Reg_Acc_Marker, t.Reg_Acc_Data_Marker,
        t.Comp_Marker, t.Req_Resp_Marker
      ))
    end else begin
      pass_count++;
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("SB_REPORT", "--------------------------------------------------", UVM_NONE)
    `uvm_info("SB_REPORT", $sformatf("Scoreboard Statistics:"), UVM_NONE)
    `uvm_info("SB_REPORT", $sformatf("Total Transactions Checked: %0d", total_transactions), UVM_NONE)
    `uvm_info("SB_REPORT", $sformatf("Matches: %0d", pass_count), UVM_NONE)
    `uvm_info("SB_REPORT", $sformatf("Mismatches: %0d", fail_count), UVM_NONE)
    `uvm_info("SB_REPORT", "--------------------------------------------------", UVM_NONE)
    
    if (fail_count > 0) begin
        `uvm_error("SB_FAIL", "Scoreboard detected mismatches during simulation.")
    end
  endfunction
endclass

`endif // WR_CONTROL_SBTX_SCOREBOARD_SVH