`ifndef WR_CONTROL_SBTX_SUBSCRIBER_SVH
`define WR_CONTROL_SBTX_SUBSCRIBER_SVH

class wr_control_sbtx_subscriber extends uvm_subscriber #(wr_control_sbtx_sequence_item);
  `uvm_component_utils(wr_control_sbtx_subscriber)

  // Transaction currently being sampled
  wr_control_sbtx_sequence_item cov_tr;

  // Output-side helper: distinguish 64-bit Header vs. Data write cycle
  bit is_data_cycle = 1'b0;

  // Input-side lightweight tracker for VPlan COV_01..COV_12
  typedef enum bit [2:0] {
    PH_IDLE = 3'd0,
    PH_HP0  = 3'd1,
    PH_HP1  = 3'd2,
    PH_DP0  = 3'd3,
    PH_DP1  = 3'd4
  } cov_phase_e;

  typedef enum bit [1:0] {
    PAR_CLEAN     = 2'd0,
    PAR_CP_ONLY   = 2'd1,
    PAR_DP_ONLY   = 2'd2,
    PAR_CP_AND_DP = 2'd3
  } parity_cause_e;

  typedef enum bit [2:0] {
    CAT_RAR_2PH  = 3'd0,
    CAT_RAR_4PH  = 3'd1,
    CAT_COMP_2PH = 3'd2,
    CAT_COMP_4PH = 3'd3,
    CAT_MSG_2PH  = 3'd4,
    CAT_MSG_4PH  = 3'd5,
    CAT_RESERVED = 3'd6
  } pkt_cat_e;

  typedef enum bit [1:0] {
    B2B_2_TO_2 = 2'd0,
    B2B_2_TO_4 = 2'd1,
    B2B_4_TO_2 = 2'd2,
    B2B_4_TO_4 = 2'd3
  } b2b_trans_e;

  cov_phase_e    cur_phase       = PH_IDLE;
  cov_phase_e    rst_phase_snap  = PH_IDLE;
  logic [4:0]    in_opcode       = '0;
  logic [7:0]    in_msgcode      = '0;
  logic [31:0]   in_hdr0         = '0;
  logic [31:0]   in_hdr1         = '0;
  logic [31:0]   in_data0        = '0;
  bit            in_has_data     = 1'b0;
  bit            in_cp_err       = 1'b0;
  bit            in_dp_exp       = 1'b0;
  bit            in_is_req_resp  = 1'b0;
  bit            in_is_msg       = 1'b0;
  bit            in_is_rar       = 1'b0;
  bit            in_rar_be_coll  = 1'b0;
  bit            pkt_done        = 1'b0;
  bit            has_prev_pkt    = 1'b0;
  bit            prev_has_data   = 1'b0;
  int            idle_gap_cnt    = 0;
  int            sampled_gap     = 0;
  bit            b2b_valid       = 1'b0;
  b2b_trans_e    b2b_trans       = B2B_2_TO_2;
  parity_cause_e parity_cause    = PAR_CLEAN;
  pkt_cat_e      pkt_cat         = CAT_RAR_2PH;

  // ---------------------------------------------------------------------
  // 1. Pin-Level, Output Markers, & Bus Covergroup
  // ---------------------------------------------------------------------
  covergroup wr_control_sbtx_cg;
    option.per_instance = 1;

    cp_RST_n: coverpoint cov_tr.RST_n {
      bins asserted_low    = {1'b0};
      bins deasserted_high = {1'b1};
    }

    cp_lp_cfg_vld: coverpoint cov_tr.lp_cfg_vld {
      bins idle  = {1'b0};
      bins valid = {1'b1};
    }

    cp_lp_cfg_vld_trans: coverpoint cov_tr.lp_cfg_vld iff (cov_tr.RST_n) {
      bins idle_to_valid = (1'b0 => 1'b1);
      bins back_to_back  = (1'b1 [*4:8]);
      bins valid_to_idle = (1'b1 => 1'b0);
      bins stay_idle     = (1'b0 => 1'b0);
    }

    cross_rst_lp_cfg_vld: cross cp_RST_n, cp_lp_cfg_vld;

    cp_lp_cfg: coverpoint cov_tr.lp_cfg iff (cov_tr.RST_n && cov_tr.lp_cfg_vld) {
      option.auto_bin_max = 16;
    }

    cp_Interface_Message: coverpoint cov_tr.Interface_Message iff (cov_tr.RST_n && cov_tr.FIFO_WR) {
      option.auto_bin_max = 16;
    }

    // COV_04: Individual Output Markers & Control Flags
    cp_Data_Marker:         coverpoint cov_tr.Data_Marker         iff (cov_tr.RST_n && cov_tr.FIFO_WR);
    cp_Reg_Acc_Marker:      coverpoint cov_tr.Reg_Acc_Marker      iff (cov_tr.RST_n && cov_tr.FIFO_WR);
    cp_Reg_Acc_Data_Marker: coverpoint cov_tr.Reg_Acc_Data_Marker iff (cov_tr.RST_n && cov_tr.FIFO_WR);
    cp_Comp_Marker:         coverpoint cov_tr.Comp_Marker         iff (cov_tr.RST_n && cov_tr.FIFO_WR);
    cp_Req_Resp_Marker:     coverpoint cov_tr.Req_Resp_Marker     iff (cov_tr.RST_n && cov_tr.FIFO_WR);
    cp_FIFO_WR:             coverpoint cov_tr.FIFO_WR             iff (cov_tr.RST_n);
    cp_UIE:                 coverpoint cov_tr.UIE                 iff (cov_tr.RST_n);
    cp_Error_Handler:       coverpoint cov_tr.Error_Handler       iff (cov_tr.RST_n);

    // COV_08: Error output combinations (UIE=1 & Error_Handler=1 vs UIE=1 & Error_Handler=0)
    cross_err_handler_uie_wr: cross cp_Error_Handler, cp_UIE iff (cov_tr.RST_n) {
      ignore_bins uie_low_err_high = binsof(cp_UIE) intersect {1'b0} &&
                                     binsof(cp_Error_Handler) intersect {1'b1};
    }

    // Output Header Opcode coverage
    cp_all_opcodes: coverpoint cov_tr.Interface_Message[4:0] iff (cov_tr.RST_n && cov_tr.FIFO_WR && !is_data_cycle) {
      bins MEM_RD_32B         = {SB_MEM_RD_32B};
      bins MEM_WR_32B         = {SB_MEM_WR_32B};
      bins CFG_RD_32B         = {SB_CFG_RD_32B};
      bins CFG_WR_32B         = {SB_CFG_WR_32B};
      bins MEM_RD_64B         = {SB_MEM_RD_64B};
      bins MEM_WR_64B         = {SB_MEM_WR_64B};
      bins CFG_RD_64B         = {SB_CFG_RD_64B};
      bins CFG_WR_64B         = {SB_CFG_WR_64B};
      bins CMPL_NO_DATA       = {SB_CMPL_NO_DATA};
      bins CMPL_WITH_32B_DATA = {SB_CMPL_WITH_32B_DATA};
      bins MSG_NO_DATA        = {SB_MSG_NO_DATA};
      bins CMPL_WITH_64B_DATA = {SB_CMPL_WITH_64B_DATA};
      bins MSG_WITH_64B_DATA  = {SB_MSG_WITH_64B_DATA};
    }

    // COV_05: Valid Marker Combinations on Header Output Cycle
    cross_markers_valid_only: cross cp_Data_Marker, cp_Reg_Acc_Marker, cp_Reg_Acc_Data_Marker, cp_Comp_Marker, cp_Req_Resp_Marker
      iff (cov_tr.RST_n && cov_tr.FIFO_WR && !is_data_cycle) {
      ignore_bins invalid_rar_data_1 = binsof(cp_Reg_Acc_Data_Marker) intersect {1'b1} &&
                                       (binsof(cp_Reg_Acc_Marker) intersect {1'b0} || binsof(cp_Data_Marker) intersect {1'b1});
      ignore_bins rar_and_comp       = binsof(cp_Reg_Acc_Marker) intersect {1'b1} &&
                                       binsof(cp_Comp_Marker) intersect {1'b1};
      ignore_bins req_resp_non_msg   = binsof(cp_Req_Resp_Marker) intersect {1'b1} &&
                                       (binsof(cp_Reg_Acc_Marker) intersect {1'b1} || binsof(cp_Comp_Marker) intersect {1'b1});
      ignore_bins req_resp_with_data = binsof(cp_Req_Resp_Marker) intersect {1'b1} &&
                                       binsof(cp_Data_Marker) intersect {1'b1};
    }

    cp_header_cp_bit: coverpoint cov_tr.Interface_Message[62] iff (cov_tr.RST_n && cov_tr.FIFO_WR && !is_data_cycle);
    cp_header_dp_bit: coverpoint cov_tr.Interface_Message[63] iff (cov_tr.RST_n && cov_tr.FIFO_WR && !is_data_cycle);
    cross_cp_dp_bits: cross cp_header_cp_bit, cp_header_dp_bit;
  endgroup : wr_control_sbtx_cg

  // ---------------------------------------------------------------------
  // 2. Packet-Level VPlan Covergroup (COV_01, COV_02, COV_03, COV_06, COV_07, COV_12)
  // ---------------------------------------------------------------------
  covergroup cg_packet_vplan;
    option.per_instance = 1;

    // COV_01: All 13 Valid Opcodes + Reserved Opcode bin
    cp_in_opcode: coverpoint in_opcode {
      bins MEM_RD_32B         = {SB_MEM_RD_32B};
      bins MEM_WR_32B         = {SB_MEM_WR_32B};
      bins CFG_RD_32B         = {SB_CFG_RD_32B};
      bins CFG_WR_32B         = {SB_CFG_WR_32B};
      bins MEM_RD_64B         = {SB_MEM_RD_64B};
      bins MEM_WR_64B         = {SB_MEM_WR_64B};
      bins CFG_RD_64B         = {SB_CFG_RD_64B};
      bins CFG_WR_64B         = {SB_CFG_WR_64B};
      bins CMPL_NO_DATA       = {SB_CMPL_NO_DATA};
      bins CMPL_WITH_32B_DATA = {SB_CMPL_WITH_32B_DATA};
      bins MSG_NO_DATA        = {SB_MSG_NO_DATA};
      bins CMPL_WITH_64B_DATA = {SB_CMPL_WITH_64B_DATA};
      bins MSG_WITH_64B_DATA  = {SB_MSG_WITH_64B_DATA};
      bins RESERVED           = default;
    }

    // COV_02: All Req/Resp and Non-Req/Resp MsgCodes (for both MSG_NO_DATA & MSG_WITH_64B_DATA)
    cp_msgcode: coverpoint in_msgcode iff (in_is_msg) {
      bins d2d_req_resp = {SB_D2D0_LINK_MGMT_REQ, SB_D2D0_LINK_MGMT_RESP,
                           SB_D2D1_LINK_MGMT_REQ, SB_D2D1_LINK_MGMT_RESP,
                           SB_D2D_PARITY_FEAT_REQ};
      bins rdi_parity   = {SB_RDI_LINK_MGMT_REQ, SB_RDI_LINK_MGMT_RESP, SB_PARITY_FEAT_ACK};
      bins ltsm_req_rsp = {SB_REQ_TESTS, SB_RESP_TESTS, SB_REQ_SB, SB_RESP_SB,
                           SB_REQ_MBINIT, SB_RESP_MBINIT, SB_REQ_MBTRAIN, SB_RESP_MBTRAIN,
                           SB_PHYRETRAIN_REQ, SB_PHYRETRAIN_RESP, SB_RECAL_REQ, SB_RECAL_RESP,
                           SB_TRAINERROR_REQ, SB_TRAINERROR_RESP};
      bins nop_credit   = {SB_NOP_CREDIT};
      bins err_msg      = {SB_ERR_MSG};
      bins sweep_sb_dn  = {SB_SWEEP_DONE, SB_SB_DONE};
      bins vendor_def   = {SB_VENDOR_DEFINED};
    }

    // COV_03: Cross {MSG_NO_DATA, MSG_WITH_64B_DATA} x {req_resp, non_req_resp}
    cp_msg_op: coverpoint in_opcode iff (in_is_msg) {
      bins msg_no_data   = {SB_MSG_NO_DATA};
      bins msg_with_data = {SB_MSG_WITH_64B_DATA};
    }
    cp_msg_req_resp: coverpoint in_is_req_resp iff (in_is_msg) {
      bins non_req_resp = {1'b0};
      bins req_resp     = {1'b1};
    }
    cx_msg_opcode_code: cross cp_msg_op, cp_msg_req_resp {
      ignore_bins msg_with_data_req_resp = binsof(cp_msg_op.msg_with_data) &&
                                           binsof(cp_msg_req_resp.req_resp);
    }

    // COV_06 & COV_07: Granular Parity Error Cause x Packet Category
    cp_parity_err: coverpoint parity_cause {
      bins clean     = {PAR_CLEAN};
      bins cp_only   = {PAR_CP_ONLY};
      bins dp_only   = {PAR_DP_ONLY};
      bins cp_and_dp = {PAR_CP_AND_DP};
    }

    cp_pkt_cat: coverpoint pkt_cat {
      bins rar_2ph  = {CAT_RAR_2PH};
      bins rar_4ph  = {CAT_RAR_4PH};
      bins comp_2ph = {CAT_COMP_2PH};
      bins comp_4ph = {CAT_COMP_4PH};
      bins msg_2ph  = {CAT_MSG_2PH};
      bins msg_4ph  = {CAT_MSG_4PH};
      ignore_bins reserved = {CAT_RESERVED};
    }

    cx_opcode_parity: cross cp_pkt_cat, cp_parity_err;

    // COV_12: RAR Byte-Enable [21:14] colliding with req_resp_msgcodes
    cp_rar_be_collision: coverpoint in_rar_be_coll iff (in_is_rar) {
      bins no_collision = {1'b0};
      bins collision    = {1'b1};
    }
  endgroup : cg_packet_vplan

  // ---------------------------------------------------------------------
  // 3. Pipeline & Reset Corner-Case Covergroups (COV_09, COV_10, COV_11)
  // ---------------------------------------------------------------------
  covergroup cg_pipeline_vplan;
    option.per_instance = 1;

    // COV_09: Back-to-back packet length transitions (idle_gap == 0)
    cx_b2b_len_trans: coverpoint b2b_trans iff (b2b_valid) {
      bins b2b_2ph_to_2ph = {B2B_2_TO_2};
      bins b2b_2ph_to_4ph = {B2B_2_TO_4};
      bins b2b_4ph_to_2ph = {B2B_4_TO_2};
      bins b2b_4ph_to_4ph = {B2B_4_TO_4};
    }

    // COV_10: Inter-packet idle gap lengths
    cp_idle_gaps: coverpoint sampled_gap {
      bins zero_b2b = {0};
      bins one_cyc  = {1};
      bins two_three = {[2:3]};
      bins four_plus = {[4:$]};
    }
  endgroup : cg_pipeline_vplan

  covergroup cg_reset_vplan;
    option.per_instance = 1;

    // COV_11: Reset asserted during {Idle, HP1, DP0, DP1} x lp_cfg_vld
    cp_rst_phase: coverpoint rst_phase_snap {
      bins rst_idle = {PH_IDLE};
      bins rst_hp1  = {PH_HP1};
      bins rst_dp0  = {PH_DP0};
      bins rst_dp1  = {PH_DP1};
    }
    cp_rst_vld: coverpoint cov_tr.lp_cfg_vld {
      bins vld_0 = {1'b0};
      bins vld_1 = {1'b1};
    }
    cx_rst_phase: cross cp_rst_phase, cp_rst_vld;
  endgroup : cg_reset_vplan

  function new(string name = "wr_control_sbtx_subscriber", uvm_component parent = null);
    super.new(name, parent);
    cov_tr            = wr_control_sbtx_sequence_item#()::type_id::create("cov_tr");
    wr_control_sbtx_cg = new();
    cg_packet_vplan    = new();
    cg_pipeline_vplan  = new();
    cg_reset_vplan     = new();
  endfunction : new

  function void write(wr_control_sbtx_sequence_item t);
    req_resp_msgcode_e tmp_rr;
    bit                dp_err_now;
    logic [63:0]       hdr64, dat64;

    if (t == null) begin
      `uvm_error("WR_CONTROL_SBTX_COV", "Received a null transaction")
      return;
    end
    cov_tr = t;

    // 1. Sample cycle-by-cycle pin & output covergroup
    wr_control_sbtx_cg.sample();

    // Update output Header vs. Data cycle tracker
    if (!t.RST_n) begin
      is_data_cycle = 1'b0;
    end else if (t.FIFO_WR) begin
      is_data_cycle = (!is_data_cycle && t.Data_Marker);
    end

    // 2. Sample Reset Phase covergroup (COV_11) and reset input tracker
    if (!t.RST_n) begin
      rst_phase_snap = cur_phase;
      cg_reset_vplan.sample();
      cur_phase    = PH_IDLE;
      has_prev_pkt = 1'b0;
      idle_gap_cnt = 0;
      return;
    end

    // 3. Track incoming packet phases for VPlan covergroups
    pkt_done = 1'b0;

    if (!t.lp_cfg_vld) begin
      if (cur_phase == PH_IDLE)
        idle_gap_cnt++;
    end else begin
      case (cur_phase)
        PH_IDLE, PH_HP0: begin
          in_hdr0        = t.lp_cfg;
          in_opcode      = t.lp_cfg[4:0];
          in_msgcode     = t.lp_cfg[21:14];
          in_is_msg      = (in_opcode inside {msg_packets});
          in_is_rar      = (in_opcode inside {rar_packets});
          in_has_data    = (in_opcode inside {data_packets});
          in_is_req_resp = (in_opcode == SB_MSG_NO_DATA) && $cast(tmp_rr, in_msgcode);
          in_rar_be_coll = in_is_rar && $cast(tmp_rr, in_msgcode);

          if (in_is_rar)
            pkt_cat = in_has_data ? CAT_RAR_4PH : CAT_RAR_2PH;
          else if (in_opcode inside {comp_packets})
            pkt_cat = in_has_data ? CAT_COMP_4PH : CAT_COMP_2PH;
          else if (in_is_msg)
            pkt_cat = in_has_data ? CAT_MSG_4PH : CAT_MSG_2PH;
          else
            pkt_cat = CAT_RESERVED;

          // Sample inter-packet gap & back-to-back transition (COV_09 & COV_10)
          if (has_prev_pkt) begin
            sampled_gap = idle_gap_cnt;
            b2b_valid   = (idle_gap_cnt == 0);
            if (b2b_valid) begin
              case ({prev_has_data, in_has_data})
                2'b00: b2b_trans = B2B_2_TO_2;
                2'b01: b2b_trans = B2B_2_TO_4;
                2'b10: b2b_trans = B2B_4_TO_2;
                2'b11: b2b_trans = B2B_4_TO_4;
              endcase
            end
            cg_pipeline_vplan.sample();
          end

          idle_gap_cnt = 0;
          cur_phase    = PH_HP1;
        end

        PH_HP1: begin
          in_hdr1   = t.lp_cfg;
          hdr64     = {in_hdr1, in_hdr0};
          in_cp_err = (in_hdr1[30] != ^hdr64[61:0]);
          in_dp_exp = in_hdr1[31];

          if (!in_has_data) begin
            dp_err_now   = (in_dp_exp != 1'b0);
            parity_cause = parity_cause_e'({dp_err_now, in_cp_err});
            pkt_done     = 1'b1;
            cur_phase    = PH_IDLE;
          end else begin
            cur_phase    = PH_DP0;
          end
        end

        PH_DP0: begin
          in_data0  = t.lp_cfg;
          cur_phase = PH_DP1;
        end

        PH_DP1: begin
          dat64        = {t.lp_cfg, in_data0};
          dp_err_now   = (in_dp_exp != ^dat64);
          parity_cause = parity_cause_e'({dp_err_now, in_cp_err});
          pkt_done     = 1'b1;
          cur_phase    = PH_IDLE;
        end
      endcase

      if (pkt_done) begin
        cg_packet_vplan.sample();
        prev_has_data = in_has_data;
        has_prev_pkt  = 1'b1;
      end
    end
  endfunction : write

endclass : wr_control_sbtx_subscriber

`endif // WR_CONTROL_SBTX_SUBSCRIBER_SVH