`ifndef DESERIALIZER_SBRX_SUBSCRIBER_SVH
`define DESERIALIZER_SBRX_SUBSCRIBER_SVH

class Deserializer_SBRX_subscriber extends uvm_component;
  `uvm_component_utils(Deserializer_SBRX_subscriber)

  // Handle to the transaction currently being sampled.
  Deserializer_SBRX_sequence_item cov_tr;

  uvm_analysis_export #(Deserializer_SBRX_sequence_item) exp;
  uvm_tlm_analysis_fifo #(Deserializer_SBRX_sequence_item) fifo;
  uvm_analysis_export #(Deserializer_SBRX_sequence_item) exp2;
  uvm_tlm_analysis_fifo #(Deserializer_SBRX_sequence_item) fifo2;

  int unsigned total_samples;

  // ---------------------------------------------------------------------
  // Functional Coverage: Deserializer_SBRX_cg
  // ---------------------------------------------------------------------
  covergroup Deserializer_SBRX_cg;
    option.per_instance = 1;
    option.comment      = "Deserializer_SBRX Functional Coverage";

    // -------------------------------------------------------------------
    // 1. Reset Signal Coverage (sb_sys_rst)
    // -------------------------------------------------------------------
    cp_sb_sys_rst: coverpoint cov_tr.sb_sys_rst {
      bins active         = {1'b0};
      bins inactive       = {1'b1};
      bins trans_assert   = (1'b1 => 1'b0);
      bins trans_deassert = (1'b0 => 1'b1);
    }

    // -------------------------------------------------------------------
    // 2. Serial Input Data Line Coverage (RXDATASB)
    // -------------------------------------------------------------------
    cp_RXDATASB: coverpoint cov_tr.RXDATASB {
      bins bit_zero  = {1'b0};
      bins bit_one   = {1'b1};
      bins trans_0_0 = (1'b0 => 1'b0);
      bins trans_0_1 = (1'b0 => 1'b1);
      bins trans_1_0 = (1'b1 => 1'b0);
      bins trans_1_1 = (1'b1 => 1'b1);
    }

    // -------------------------------------------------------------------
    // 3. Output Handshake (data_valid) Single-Cycle Pulse Coverage
    // -------------------------------------------------------------------
    cp_data_valid: coverpoint cov_tr.data_valid {
      bins deasserted         = {1'b0};
      bins asserted           = {1'b1};
      bins single_cycle_pulse = (1'b0 => 1'b1 => 1'b0);
    }

    // -------------------------------------------------------------------
    // 4. Parallel Output Word (deser_data_out) Coverage when valid
    // -------------------------------------------------------------------
    cp_deser_data_out: coverpoint cov_tr.deser_data_out iff (cov_tr.data_valid && cov_tr.sb_sys_rst) {
      bins all_zeros      = {64'h0000_0000_0000_0000};
      bins all_ones       = {64'hFFFF_FFFF_FFFF_FFFF};
      bins alt_01         = {64'h5555_5555_5555_5555};
      bins alt_10         = {64'hAAAA_AAAA_AAAA_AAAA};
      bins lsb_bit_only   = {64'h0000_0000_0000_0001};
      bins msb_bit_only   = {64'h8000_0000_0000_0000};
      bins auto_ranges[8] = {[64'h0000_0000_0000_0001 : 64'hFFFF_FFFF_FFFF_FFFE]};
    }

    // Byte-level distribution coverage for the 64-bit reconstructed word
    cp_deser_byte0: coverpoint cov_tr.deser_data_out[7:0] iff (cov_tr.data_valid && cov_tr.sb_sys_rst) {
      bins byte0_zero     = {8'h00};
      bins byte0_ones     = {8'hFF};
      bins byte0_alt55    = {8'h55};
      bins byte0_altAA    = {8'hAA};
      bins byte_ranges[4] = {[8'h00 : 8'hFF]};
    }

    cp_deser_byte7: coverpoint cov_tr.deser_data_out[63:56] iff (cov_tr.data_valid && cov_tr.sb_sys_rst) {
      bins byte7_zero     = {8'h00};
      bins byte7_ones     = {8'hFF};
      bins byte7_alt55    = {8'h55};
      bins byte7_altAA    = {8'hAA};
      bins byte_ranges[4] = {[8'h00 : 8'hFF]};
    }

    // -------------------------------------------------------------------
    // 5. Cross Coverage: Reset vs data_valid
    // -------------------------------------------------------------------
    cross_rst_valid: cross cp_sb_sys_rst, cp_data_valid {
      ignore_bins rst_trans          = binsof(cp_sb_sys_rst.trans_assert) || binsof(cp_sb_sys_rst.trans_deassert);
      ignore_bins valid_trans        = binsof(cp_data_valid.single_cycle_pulse);
      ignore_bins invalid_during_rst = binsof(cp_sb_sys_rst.active) && binsof(cp_data_valid.asserted);
    }

    // -------------------------------------------------------------------
    // 6. Cross Coverage: Reset vs RXDATASB
    // -------------------------------------------------------------------
    cross_rst_rx_data: cross cp_sb_sys_rst, cp_RXDATASB {
      ignore_bins rst_trans  = binsof(cp_sb_sys_rst.trans_assert) || binsof(cp_sb_sys_rst.trans_deassert);
      ignore_bins data_trans = binsof(cp_RXDATASB.trans_0_0) || binsof(cp_RXDATASB.trans_0_1) ||
                               binsof(cp_RXDATASB.trans_1_0) || binsof(cp_RXDATASB.trans_1_1);
    }

  endgroup : Deserializer_SBRX_cg

  function new(string name = "Deserializer_SBRX_subscriber", uvm_component parent = null);
    super.new(name, parent);
    Deserializer_SBRX_cg = new();
    total_samples = 0;
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    exp   = new("exp", this);
    fifo  = new("fifo", this);
    exp2  = new("exp2", this);
    fifo2 = new("fifo2", this);
  endfunction : build_phase

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    exp.connect(fifo.analysis_export);
    exp2.connect(fifo2.analysis_export);
  endfunction : connect_phase

  task run_phase(uvm_phase phase);
    Deserializer_SBRX_sequence_item item;
    Deserializer_SBRX_sequence_item item2;
    Deserializer_SBRX_sequence_item check_item;
    super.run_phase(phase);
    forever begin
      fifo.get(item);
      fifo2.get(item2);
      check_item = Deserializer_SBRX_sequence_item::type_id::create("check_item");
      check_item.sb_sys_rst = item.sb_sys_rst;
      check_item.deser_data_out = item.deser_data_out;
      check_item.data_valid = item.data_valid;
      check_item.RXDATASB = item2.RXDATASB;
      sample_item(check_item);
    end
  endtask : run_phase

  function void sample_item(Deserializer_SBRX_sequence_item t);
    if (t == null) begin
      `uvm_error("DESERIALIZER_SBRX_COV", "Received a null transaction")
      return;
    end
    cov_tr = t;
    total_samples++;
    Deserializer_SBRX_cg.sample();
  endfunction : sample_item

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("COV_REPORT", "============================================================", UVM_NONE)
    `uvm_info("COV_REPORT", "         DESERIALIZER_SBRX COVERAGE REPORT                  ", UVM_NONE)
    `uvm_info("COV_REPORT", "============================================================", UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf(" Total Samples Monitored : %0d", total_samples), UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf(" Functional Coverage     : %0.2f %%", Deserializer_SBRX_cg.get_inst_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", "============================================================", UVM_NONE)
  endfunction : report_phase

endclass : Deserializer_SBRX_subscriber

`endif // DESERIALIZER_SBRX_SUBSCRIBER_SVH
