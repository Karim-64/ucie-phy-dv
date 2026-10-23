`ifndef WR_CONTROL_SBTX_SUBSCRIBER_SVH
`define WR_CONTROL_SBTX_SUBSCRIBER_SVH

class wr_control_sbtx_subscriber extends uvm_subscriber #(wr_control_sbtx_sequence_item);
  `uvm_component_utils(wr_control_sbtx_subscriber)

  // Handle to the transaction currently being sampled.
  wr_control_sbtx_sequence_item cov_tr;

  // Helper flag to distinguish the 64-bit Header write cycle from the 64-bit Data write cycle
  //first cycle is header
  //Rst is handled in covergroup
  bit is_data_cycle = 1'b0;

  // ---------------------------------------------------------------------
  // Functional Coverage
  // ---------------------------------------------------------------------
  covergroup wr_control_sbtx_cg;
    //option.per_instance = 1;

    // Pin-Level & Reset / Valid Transition Coverpoints
    cp_RST_n: coverpoint cov_tr.RST_n {
      bins asserted_low    = {1'b0};
      bins deasserted_high = {1'b1};
    }

    cp_lp_cfg_vld: coverpoint cov_tr.lp_cfg_vld {
      bins idle  = {1'b0};
      bins valid = {1'b1};
    }

    //Transition coverage on lp_cfg_vld (Idle -> Valid, Back-to-Back, Valid -> Idle)
    cp_lp_cfg_vld_trans: coverpoint cov_tr.lp_cfg_vld iff (cov_tr.RST_n) {
      bins idle_to_valid = (1'b0 => 1'b1);
      bins back_to_back  = (1'b1 [*4:8]); // Continuous valid phases across packet boundaries
      bins valid_to_idle = (1'b1 => 1'b0);
      bins stay_idle     = (1'b0 => 1'b0);
    }

    // Cross RST_n with lp_cfg_vld
    cross_rst_lp_cfg_vld: cross cp_RST_n, cp_lp_cfg_vld;

    // Raw data bus 
    cp_lp_cfg: coverpoint cov_tr.lp_cfg iff (cov_tr.RST_n && cov_tr.lp_cfg_vld) {
      option.auto_bin_max = 16;
    }
    cp_Interface_Message: coverpoint cov_tr.Interface_Message iff (cov_tr.RST_n && cov_tr.FIFO_WR) {
      option.auto_bin_max = 16;
    }

    //Individual Output Markers
    cp_Data_Marker:         coverpoint cov_tr.Data_Marker         iff (cov_tr.RST_n && cov_tr.FIFO_WR);
    cp_Reg_Acc_Marker:      coverpoint cov_tr.Reg_Acc_Marker      iff (cov_tr.RST_n && cov_tr.FIFO_WR);
    cp_Reg_Acc_Data_Marker: coverpoint cov_tr.Reg_Acc_Data_Marker iff (cov_tr.RST_n && cov_tr.FIFO_WR);
    cp_Comp_Marker:         coverpoint cov_tr.Comp_Marker         iff (cov_tr.RST_n && cov_tr.FIFO_WR);
    cp_Req_Resp_Marker:     coverpoint cov_tr.Req_Resp_Marker     iff (cov_tr.RST_n && cov_tr.FIFO_WR);
    cp_Error_Handler:       coverpoint cov_tr.Error_Handler       iff (cov_tr.RST_n && cov_tr.FIFO_WR);
    cp_FIFO_WR:             coverpoint cov_tr.FIFO_WR             iff (cov_tr.RST_n);
    cp_UIE:                 coverpoint cov_tr.UIE                 iff (cov_tr.RST_n && cov_tr.FIFO_WR);

    //All Opcodes (Sampled on Valid Header Write Cycles)
    cp_all_opcodes: coverpoint cov_tr.Interface_Message[4:0] iff (cov_tr.RST_n && cov_tr.FIFO_WR && !is_data_cycle) {
      bins MEM_RD_32B         = {5'b00000};
      bins MEM_WR_32B         = {5'b00001};
      bins CFG_RD_32B         = {5'b00100};
      bins CFG_WR_32B         = {5'b00101};
      bins MEM_RD_64B         = {5'b01000};
      bins MEM_WR_64B         = {5'b01001};
      bins CFG_RD_64B         = {5'b01100};
      bins CFG_WR_64B         = {5'b01101};
      bins CMPL_NO_DATA       = {5'b10000};
      bins CMPL_WITH_32B_DATA = {5'b10001};
      bins MSG_NO_DATA        = {5'b10010};
      bins CMPL_WITH_64B_DATA = {5'b11001};
      bins MSG_WITH_64B_DATA  = {5'b11011};
    }

    cross_err_handler_uie_wr: cross cp_Error_Handler, cp_UIE iff (cov_tr.RST_n) {
        ignore_bins uie_low_err_high = binsof(cp_UIE) intersect {1'b0} &&
                                       binsof(cp_Error_Handler) intersect {1'b1};
    }
    // Cross Marker Flags (Possible Values Only)
    cross_markers_valid_only: cross cp_Data_Marker, cp_Reg_Acc_Marker, cp_Reg_Acc_Data_Marker, cp_Comp_Marker, cp_Req_Resp_Marker iff (cov_tr.RST_n && cov_tr.FIFO_WR && !is_data_cycle) {
          //Reg_Acc_Data_Marker can ONLY be 1 when BOTH Data_Marker==0 and Reg_Acc_Marker==1 (register read only)
          ignore_bins invalid_rar_data_1 = binsof(cp_Reg_Acc_Data_Marker) intersect {1'b1} &&
                                           (binsof(cp_Data_Marker) intersect {1'b1} || binsof(cp_Reg_Acc_Marker) intersect {1'b0});

          //Reg_Acc_Marker and Comp_Marker are mutually exclusive (a packet cannot be both RAR and Completion)
          ignore_bins rar_and_comp = binsof(cp_Reg_Acc_Marker) intersect {1'b1} &&
                                     binsof(cp_Comp_Marker) intersect {1'b1};

          //Req_Resp_Marker is only for Messages (never asserted on RAR or Completion)
          ignore_bins req_resp_on_rar_or_comp = binsof(cp_Req_Resp_Marker) intersect {1'b1} &&
                                                (binsof(cp_Reg_Acc_Marker) intersect {1'b1} || binsof(cp_Comp_Marker) intersect {1'b1});
        }  

    //msg_code = 7, 8, 9 for opcode MSG_NO_DATA (5'b10010)
    cp_msg_no_data_msgcodes: coverpoint cov_tr.Interface_Message[21:14]
      iff (cov_tr.RST_n && cov_tr.FIFO_WR && !is_data_cycle && (cov_tr.Interface_Message[4:0] == 5'b10010)) {
      bins parity_feat_req     = {8'h07}; // MsgCode = 7 ({ParityFeature.Req})
      bins parity_feat_ack_nak = {8'h08}; // MsgCode = 8 ({ParityFeature.Ack/Nak})
      bins err_msg             = {8'h09}; // MsgCode = 9 ({ErrMsg})
      bins link_mgmt_msgs      = {[8'h01:8'h06]};
      bins ltsm_msgs           = {8'h85, 8'h8A, 8'hA5, 8'hAA, 8'hB5, 8'hBA, 8'hC5, 8'hCA, 8'hD5, 8'hDA, 8'hE5, 8'hEA};
    }

    // Cross Opcode with Parity Error (UIE) to ensure every opcode was tested both Error-Free and with Parity Error
    cross_opcode_uie: cross cp_all_opcodes, cp_UIE iff (cov_tr.RST_n && cov_tr.FIFO_WR && !is_data_cycle);

    // 3. Control Parity (CP) & Data Parity (DP) bit toggle coverage
    cp_header_cp_bit: coverpoint cov_tr.Interface_Message[62] iff (cov_tr.RST_n && cov_tr.FIFO_WR && !is_data_cycle);
    cp_header_dp_bit: coverpoint cov_tr.Interface_Message[63] iff (cov_tr.RST_n && cov_tr.FIFO_WR && !is_data_cycle);
    cross_cp_dp_bits: cross cp_header_cp_bit, cp_header_dp_bit;

  endgroup : wr_control_sbtx_cg

  function new(string name = "wr_control_sbtx_subscriber", uvm_component parent = null);
    super.new(name, parent);
    cov_tr = wr_control_sbtx_sequence_item#()::type_id::create("cov_tr");
    wr_control_sbtx_cg = new();
  endfunction : new

  function void write(wr_control_sbtx_sequence_item t);
    if (t == null) begin
      `uvm_error("WR_CONTROL_SBTX_COV", "Received a null transaction")
      return;
    end
    cov_tr = t;

    // Sample covergroup for the current cycle
    wr_control_sbtx_cg.sample();

    // Update helper state for the NEXT cycle:
    // If the DUT just wrote a Header with Data_Marker=1, the next FIFO_WR cycle is a Data payload cycle!
    if (!t.RST_n) begin
      is_data_cycle = 1'b0;
    end else if (t.FIFO_WR) begin
      if (!is_data_cycle && t.Data_Marker) begin
        is_data_cycle = 1'b1; // Next FIFO_WR is the 64-bit Data payload
      end else begin
        is_data_cycle = 1'b0; // Next FIFO_WR is a new 64-bit Header
      end
    end

  endfunction : write

endclass : wr_control_sbtx_subscriber

`endif // WR_CONTROL_SBTX_SUBSCRIBER_SVH