`ifndef PATTERN_DETECTOR_SBRX_SUBSCRIBER_SVH
`define PATTERN_DETECTOR_SBRX_SUBSCRIBER_SVH

class Pattern_detector_SBRX_subscriber extends uvm_component;
  `uvm_component_utils(Pattern_detector_SBRX_subscriber)

  // Handle to the transaction currently being sampled.
  Pattern_detector_SBRX_sequence_item cov_tr;
  uvm_analysis_export #(Pattern_detector_SBRX_sequence_item) exp;
  uvm_tlm_analysis_fifo #(Pattern_detector_SBRX_sequence_item) fifo;

  int unsigned total_samples;

  // ---------------------------------------------------------------------
  // Protocol Constants & Sampled Helper Signals
  // ---------------------------------------------------------------------
  localparam logic [63:0] CLK_PAT         = 64'h5555_5555_5555_5555;
  localparam logic [63:0] INV_CLK_PAT     = 64'hAAAA_AAAA_AAAA_AAAA;
  localparam logic [63:0] CANONICAL_SBO   = 64'h4600_0100_4024_4012;
  localparam logic [4:0]  OPC_MSG_NO_DATA = 5'b10010;
  localparam logic [7:0]  MSGCODE_SBO     = 8'h91;
  localparam logic [2:0]  SRCID_PHY       = 3'b010;
  localparam logic [2:0]  DSTID_REM_PHY   = 3'b110;

  // Extracted header fields from pattern_data_in[63:0] (UCIe 3.0 Fig 7-3 & Table 7-9)
  logic [4:0]  opc_s;
  logic [8:0]  rsvd_p0_lo_s;
  logic [7:0]  msgcode_s;
  logic [6:0]  rsvd_p0_hi_s;
  logic [2:0]  srcid_s;
  logic [7:0]  msgsubcode_s;
  logic [3:0]  result_s;
  logic [11:0] msginfo_s;
  logic [2:0]  dstid_s;
  logic [2:0]  rsvd_p1_hi_s;
  logic        cp_bit_s;
  logic        dp_bit_s;


  bit          cp_even_valid_s;
  bit          rsvd_all_zero_s;
  bit          is_1bit_flip_clk_pat_s;
  bit          is_walking_one_s;
  bit          is_walking_zero_s;

  covergroup Pattern_detector_SBRX_cg;
    option.per_instance = 1;

    cp_sb_sys_rst: coverpoint cov_tr.sb_sys_rst {
      bins active_low_reset = {1'b0};
      bins deasserted_run   = {1'b1};
      bins rst_assert_edge  = (1'b1 => 1'b0);
      bins rst_release_edge = (1'b0 => 1'b1);
      bins rst_sustained    = (1'b0 [*2:4]);
    }

    cp_data_valid: coverpoint cov_tr.data_valid {
      bins invalid_low      = {1'b0};
      bins valid_high       = {1'b1};
      bins single_strobe    = (1'b0 => 1'b1 => 1'b0);
      bins valid_drop       = (1'b1 => 1'b0);
      bins long_idle_gap    = (1'b0 [*16]);
    }

    cp_pattern_data_in: coverpoint cov_tr.pattern_data_in {
      bins exact_clk_pat_5555 = {CLK_PAT};
      bins inv_clk_pat_aaaa   = {INV_CLK_PAT};
      bins canonical_sbinit   = {CANONICAL_SBO};
      bins all_zeros          = {64'h0000_0000_0000_0000};
      bins all_ones           = {64'hFFFF_FFFF_FFFF_FFFF};
      bins other_payload      = default;
    }

    cp_single_bit_flip_pat: coverpoint is_1bit_flip_clk_pat_s iff (cov_tr.sb_sys_rst && cov_tr.data_valid) {
      bins no_1bit_flip       = {1'b0};
      bins walking_1bit_flip  = {1'b1};
    }

    cp_walking_bus_toggle: coverpoint {is_walking_one_s, is_walking_zero_s} iff (cov_tr.sb_sys_rst && cov_tr.data_valid) {
      bins walking_one        = {2'b10};
      bins walking_zero       = {2'b01};
      bins normal_data        = {2'b00};
    }

    cp_pattern_sequence: coverpoint (cov_tr.pattern_data_in == CLK_PAT) iff (cov_tr.sb_sys_rst && cov_tr.data_valid) {
      bins single_match_then_nonmatch = (1'b1 => 1'b0);
      bins two_consecutive_matches    = (1'b0 => 1'b1 [*2]);
      bins sustained_four_matches     = (1'b1 [*4]);
      bins interrupted_match_101      = (1'b1 => 1'b0 => 1'b1);
    }

    cp_opcode: coverpoint opc_s iff (cov_tr.sb_sys_rst && cov_tr.data_valid) {
      bins msg_without_data   = {OPC_MSG_NO_DATA};
      bins other_valid_ucie[] = {5'b00000, 5'b00001, 5'b00010, 5'b00011,
                                 5'b00100, 5'b00101, 5'b01000, 5'b01001,
                                 5'b10000, 5'b10001, 5'b11001, 5'b11011};
      bins invalid_opcodes[]  = default;
    }

    cp_msgcode: coverpoint msgcode_s iff (cov_tr.sb_sys_rst && cov_tr.data_valid) {
      bins sbinit_out_of_rst  = {MSGCODE_SBO};
      bins sbinit_done_req    = {8'h95};
      bins sbinit_done_resp   = {8'h9A};
      bins nop_crd            = {8'h00};
      bins all_ones_ff        = {8'hFF};
      bins other_msgcodes     = default;
    }

    cp_srcid: coverpoint srcid_s iff (cov_tr.sb_sys_rst && cov_tr.data_valid) {
      bins phy_layer_010      = {SRCID_PHY};
      bins other_srcid[]      = {[3'b000:3'b001], [3'b011:3'b111]};
    }

    cp_msgsubcode: coverpoint msgsubcode_s iff (cov_tr.sb_sys_rst && cov_tr.data_valid) {
      bins canonical_00       = {8'h00};
      bins nonzero_subcode    = {[8'h01:8'hFF]};
    }

    cp_result: coverpoint result_s iff (cov_tr.sb_sys_rst && cov_tr.data_valid) {
      bins canonical_0001     = {4'b0001};
      bins bit0_zero_even[]   = {4'h0, 4'h2, 4'h4, 4'h6, 4'h8, 4'hA, 4'hC, 4'hE};
      bins bit0_one_odd[]     = {4'h3, 4'h5, 4'h7, 4'h9, 4'hB, 4'hD, 4'hF};
    }

    cp_dstid: coverpoint dstid_s iff (cov_tr.sb_sys_rst && cov_tr.data_valid) {
      bins remote_phy_110     = {DSTID_REM_PHY};
      bins other_dstid[]      = {[3'b000:3'b101], 3'b111};
    }

    cp_control_parity: coverpoint cp_even_valid_s iff (cov_tr.sb_sys_rst && cov_tr.data_valid) {
      bins valid_even_parity  = {1'b1};
      bins parity_error_odd   = {1'b0};
    }

    cp_data_parity: coverpoint dp_bit_s iff (cov_tr.sb_sys_rst && cov_tr.data_valid) {
      bins canonical_dp_0     = {1'b0};
      bins non_canonical_dp_1 = {1'b1};
    }

    cp_reserved_fields: coverpoint rsvd_all_zero_s iff (cov_tr.sb_sys_rst && cov_tr.data_valid) {
      bins all_rsvd_zero      = {1'b1};
      bins rsvd_perturbed     = {1'b0};
    }

    cp_pattern_detected: coverpoint cov_tr.pattern_detected iff (cov_tr.sb_sys_rst) {
      bins low                = {1'b0};
      bins high               = {1'b1};
      bins rise_edge          = (1'b0 => 1'b1);
      bins fall_edge          = (1'b1 => 1'b0);
      bins retrigger_pulse    = (1'b1 => 1'b0 => 1'b1);
    }

    cp_sb_o_detected: coverpoint cov_tr.sb_o_detected iff (cov_tr.sb_sys_rst) {
      bins low                = {1'b0};
      bins high               = {1'b1};
      bins rise_edge          = (1'b0 => 1'b1);
      bins fall_edge          = (1'b1 => 1'b0);
      bins burst_high         = (1'b1 [*2:4]);
    }

    cp_joint_outputs: coverpoint {cov_tr.pattern_detected, cov_tr.sb_o_detected} iff (cov_tr.sb_sys_rst) {
      bins both_idle_00       = {2'b00};
      bins sb_o_only_01       = {2'b01};
      bins pat_only_10        = {2'b10};
      illegal_bins both_11    = {2'b11}; // Mutual exclusivity
      bins idle_to_pat        = (2'b00 => 2'b10);
      bins idle_to_sbo        = (2'b00 => 2'b01);
      bins pat_to_sbo_direct  = (2'b10 => 2'b01);
      bins sbo_to_pat_seq     = (2'b01 => 2'b00 => 2'b10);
      bins pat_to_idle        = (2'b10 => 2'b00);
      bins sbo_to_idle        = (2'b01 => 2'b00);
    }
 
  endgroup : Pattern_detector_SBRX_cg

  // ---------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------
  function new(string name = "Pattern_detector_SBRX_subscriber", uvm_component parent = null);
    super.new(name, parent);
    Pattern_detector_SBRX_cg = new();
    exp   = new("exp", this);
    fifo  = new("fifo", this);
    total_samples = 0;
  endfunction : new

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    exp.connect(fifo.analysis_export);
  endfunction : connect_phase

  task run_phase(uvm_phase phase);
    Pattern_detector_SBRX_sequence_item t;
    super.run_phase(phase);
    forever begin
      fifo.get(t);
      sample_item(t);
    end
  endtask : run_phase

  function void sample_item(Pattern_detector_SBRX_sequence_item t);
    if (t == null) begin
      `uvm_error("PATTERN_DETECTOR_SBRX_COV", "Received a null transaction")
      return;
    end
    cov_tr = t;

    // Extract UCIe 3.0 64-bit Sideband Header Fields
    opc_s          = cov_tr.pattern_data_in[4:0];
    rsvd_p0_lo_s   = cov_tr.pattern_data_in[13:5];
    msgcode_s      = cov_tr.pattern_data_in[21:14];
    rsvd_p0_hi_s   = cov_tr.pattern_data_in[28:22];
    srcid_s        = cov_tr.pattern_data_in[31:29];
    msgsubcode_s   = cov_tr.pattern_data_in[39:32];
    result_s       = cov_tr.pattern_data_in[43:40];
    msginfo_s      = cov_tr.pattern_data_in[55:44];
    dstid_s        = cov_tr.pattern_data_in[58:56];
    rsvd_p1_hi_s   = cov_tr.pattern_data_in[61:59];
    cp_bit_s       = cov_tr.pattern_data_in[62];
    dp_bit_s       = cov_tr.pattern_data_in[63];

    // Compute helper flags
    cp_even_valid_s        = (cp_bit_s == (^cov_tr.pattern_data_in[61:0]));
    rsvd_all_zero_s        = (rsvd_p0_lo_s == 9'h0) && (rsvd_p0_hi_s == 7'h0) &&
                             (msginfo_s == 12'h0)   && (rsvd_p1_hi_s == 3'b0);
    is_1bit_flip_clk_pat_s = $onehot(cov_tr.pattern_data_in ^ CLK_PAT);
    is_walking_one_s       = $onehot(cov_tr.pattern_data_in);
    is_walking_zero_s      = $onehot(~cov_tr.pattern_data_in);

    // Sample
    Pattern_detector_SBRX_cg.sample();

    total_samples++;
  endfunction : sample_item

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("COV_REPORT", "============================================================", UVM_NONE)
    `uvm_info("COV_REPORT", "      Pattern_detector_SBRX FUNCTIONAL COVERAGE REPORT      ", UVM_NONE)
    `uvm_info("COV_REPORT", "============================================================", UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf(" Total Transactions Sampled       : %0d", total_samples), UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf(" Pattern_detector_SBRX_cg Coverage: %0.2f%%", Pattern_detector_SBRX_cg.get_inst_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", "============================================================", UVM_NONE)
  endfunction : report_phase

endclass : Pattern_detector_SBRX_subscriber

`endif // PATTERN_DETECTOR_SBRX_SUBSCRIBER_SVH
