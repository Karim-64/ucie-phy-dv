`ifndef SYNC_FIFO_SBRX_SUBSCRIBER_SVH
`define SYNC_FIFO_SBRX_SUBSCRIBER_SVH

// =============================================================================
// Design Under Test: Sync_FIFO_SBRX (Single-Clock Synchronous FIFO)
// File Name        : Sync_fifo_SBRX_subscriber.svh
// Description      : Functional coverage subscriber implementing covergroups,
//                    crosses, and occupancy tracking according to Vplan.
// =============================================================================

class Sync_fifo_SBRX_subscriber extends uvm_subscriber #(Sync_fifo_SBRX_sequence_item);
  `uvm_component_utils(Sync_fifo_SBRX_subscriber)

  // Handle to the transaction currently being sampled
  Sync_fifo_SBRX_sequence_item cov_tr;

  // Analysis export & FIFO for receiving transactions from agent
  uvm_analysis_export #(Sync_fifo_SBRX_sequence_item) exp;
  uvm_tlm_analysis_fifo #(Sync_fifo_SBRX_sequence_item) fifo;

  // Tracked internal occupancy
  int unsigned occupancy;

  // ===========================================================================
  // Functional Coverage Group
  // ===========================================================================
  covergroup Sync_fifo_SBRX_cg;
    option.per_instance = 1;
    option.comment = "Sync_FIFO_SBRX Functional Coverage Model";

    // -------------------------------------------------------------------------
    // 1. Basic Interface Pin Coverpoints
    // -------------------------------------------------------------------------
    cp_sys_rst: coverpoint cov_tr.sys_rst {
      bins active_low = {1'b0};
      bins inactive   = {1'b1};
    }

    cp_wr_en: coverpoint cov_tr.wr_en {
      bins deasserted = {1'b0};
      bins asserted   = {1'b1};
    }

    cp_rd_en: coverpoint cov_tr.rd_en {
      bins deasserted = {1'b0};
      bins asserted   = {1'b1};
    }

    cp_full: coverpoint cov_tr.full {
      bins not_full     = {1'b0};
      bins full         = {1'b1};
    }

    cp_full_trans: coverpoint cov_tr.full {
      bins trans_0_to_1 = (1'b0 => 1'b1);
      bins trans_1_to_0 = (1'b1 => 1'b0);
    }

    cp_empty: coverpoint cov_tr.empty {
      bins not_empty    = {1'b0};
      bins empty        = {1'b1};
    }

    cp_empty_trans: coverpoint cov_tr.empty {
      bins trans_0_to_1 = (1'b0 => 1'b1);
      bins trans_1_to_0 = (1'b1 => 1'b0);
    }

    // -------------------------------------------------------------------------
    // 2. Protocol Operation Acceptance Table (Spec Section 3 & Vplan)
    // -------------------------------------------------------------------------
    // Note: Uses auto-cross with iff guard (Questa 2021.1 compatible).
    // ignore_bins with intersect is the only reliable cross-bin filter in this version.
    cr_operations: cross cp_wr_en, cp_rd_en, cp_full, cp_empty iff (cov_tr.sys_rst) {
      // Impossible: FIFO simultaneously full AND empty
      ignore_bins illegal_full_and_empty =
        binsof(cp_full) intersect {1'b1} && binsof(cp_empty) intersect {1'b1};
    }

    // -------------------------------------------------------------------------
    // 3. Reset Cross Coverage (CAT_RST)
    // -------------------------------------------------------------------------
    cr_rst_wr:    cross cp_sys_rst, cp_wr_en;
    cr_rst_rd:    cross cp_sys_rst, cp_rd_en;
    cr_rst_full:  cross cp_sys_rst, cp_full {
      ignore_bins rst_full_impossible = binsof(cp_sys_rst) intersect {1'b0} && binsof(cp_full) intersect {1'b1};
    }
    cr_rst_empty: cross cp_sys_rst, cp_empty {
      ignore_bins rst_not_empty_impossible = binsof(cp_sys_rst) intersect {1'b0} && binsof(cp_empty) intersect {1'b0};
    }

    // -------------------------------------------------------------------------
    // 4. Occupancy Range & Boundary Transitions Coverage (CAT_BND, CAT_FUL, CAT_EMP)
    // -------------------------------------------------------------------------
    cp_occupancy: coverpoint occupancy iff (cov_tr.sys_rst) {
      bins empty_boundary    = {0};
      bins almost_empty      = {1};
      bins low_range         = {[2 : 15]};
      bins mid_range         = {[16 : 47]};
      bins high_range        = {[48 : 62]};
      bins almost_full       = {63};
      bins full_boundary     = {64};
      bins trans_0_to_1      = (0 => 1);
      bins trans_1_to_0      = (1 => 0);
      bins trans_63_to_64    = (63 => 64);
      bins trans_64_to_63    = (64 => 63);
      bins thrash_empty      = (0 => 1 => 0);
      bins thrash_full       = (64 => 63 => 64);
    }

    // -------------------------------------------------------------------------
    // 5. Data Patterns Coverage across 65-Bit Bus (CAT_DAT)
    // -------------------------------------------------------------------------
    cp_wr_data_pattern: coverpoint cov_tr.wr_data iff (cov_tr.sys_rst && cov_tr.wr_en && !cov_tr.full) {
      bins all_zeros    = {65'h0};
      bins all_ones     = {65'h1_FFFF_FFFF_FFFF_FFFF};
      bins alt_0xAA     = {65'h0_AAAA_AAAA_AAAA_AAAA};
      bins alt_0x55     = {65'h1_5555_5555_5555_5555};
      bins msb_high     = {[65'h1_0000_0000_0000_0000 : 65'h1_FFFF_FFFF_FFFF_FFFF]};
      bins msb_low      = {[65'h0_0000_0000_0000_0000 : 65'h0_FFFF_FFFF_FFFF_FFFF]};
      bins others       = default;
    }

    // Note: rd_data is registered — the DUT outputs valid data 1 cycle after rd_en.
    // We sample whenever rd_data is non-zero and FIFO not empty (rd_en not required).
    cp_rd_data_pattern: coverpoint cov_tr.rd_data iff (cov_tr.sys_rst && !cov_tr.empty) {
      bins all_zeros    = {65'h0};
      bins all_ones     = {65'h1_FFFF_FFFF_FFFF_FFFF};
      bins alt_0xAA     = {65'h0_AAAA_AAAA_AAAA_AAAA};
      bins alt_0x55     = {65'h1_5555_5555_5555_5555};
      bins msb_high     = {[65'h1_0000_0000_0000_0000 : 65'h1_FFFF_FFFF_FFFF_FFFF]};
      bins msb_low      = {[65'h0_0000_0000_0000_0000 : 65'h0_FFFF_FFFF_FFFF_FFFF]};
      bins others       = default;
    }

    // 65th Bit (Bit 64) Dedicated Observation
    cp_wr_data_msb: coverpoint cov_tr.wr_data[DATA_WIDTH] iff (cov_tr.sys_rst && cov_tr.wr_en && !cov_tr.full) {
      bins bit64_low  = {1'b0};
      bins bit64_high = {1'b1};
    }

    cp_rd_data_msb: coverpoint cov_tr.rd_data[DATA_WIDTH] iff (cov_tr.sys_rst && cov_tr.rd_en && !cov_tr.empty) {
      bins bit64_low  = {1'b0};
      bins bit64_high = {1'b1};
    }

    // -------------------------------------------------------------------------
    // 6. Back-to-Back Consecutive Request Coverage (CAT_BAS, CAT_ORD, CAT_RND)
    // -------------------------------------------------------------------------
    cp_consecutive_writes: coverpoint cov_tr.wr_en iff (cov_tr.sys_rst) {
      bins single_wr = (1'b0 => 1'b1 => 1'b0);
      bins burst_wr  = (1'b1 [* 2:16]);
    }

    cp_consecutive_reads: coverpoint cov_tr.rd_en iff (cov_tr.sys_rst) {
      bins single_rd = (1'b0 => 1'b1 => 1'b0);
      bins burst_rd  = (1'b1 [* 2:16]);
    }

  endgroup : Sync_fifo_SBRX_cg

  // ===========================================================================
  // Methods
  // ===========================================================================

  function new(string name = "Sync_fifo_SBRX_subscriber", uvm_component parent = null);
    super.new(name, parent);
    exp   = new("exp", this);
    fifo  = new("fifo", this);
    exp.connect(fifo.analysis_export);
    Sync_fifo_SBRX_cg = new();
    occupancy = 0;
  endfunction : new

  virtual function void write(Sync_fifo_SBRX_sequence_item t);
    // Satisfies uvm_subscriber interface; item processing is handled in run_phase via fifo
  endfunction : write

  task run_phase(uvm_phase phase);
    Sync_fifo_SBRX_sequence_item t;
    super.run_phase(phase);
    forever begin
      fifo.get(t);
      sample_item(t);
    end
  endtask : run_phase

  function void sample_item(Sync_fifo_SBRX_sequence_item t);
    if (t == null) begin
      `uvm_error("SYNC_FIFO_SBRX_COV", "Received a null transaction")
      return;
    end

    // Track FIFO occupancy based on accepted operations
    if (!t.sys_rst) begin
      occupancy = 0;
    end else begin
      bit pre_full  = (occupancy == FIFO_DEPTH);
      bit pre_empty = (occupancy == 0);
      bit accepted_wr = t.wr_en && !pre_full;
      bit accepted_rd = t.rd_en && !pre_empty;

      if (accepted_wr && !accepted_rd) begin
        if (occupancy < FIFO_DEPTH) occupancy++;
      end else if (!accepted_wr && accepted_rd) begin
        if (occupancy > 0) occupancy--;
      end
      // When simultaneous accepted write and read occur, occupancy is unchanged
    end

    cov_tr = t;
    Sync_fifo_SBRX_cg.sample();
  endfunction : sample_item

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), "==================================================", UVM_NONE)
    `uvm_info(get_type_name(), "      Sync_FIFO_SBRX FUNCTIONAL COVERAGE REPORT    ", UVM_NONE)
    `uvm_info(get_type_name(), "==================================================", UVM_NONE)
    `uvm_info(get_type_name(), $sformatf(" Total Coverage Achieved : %0.2f%%", Sync_fifo_SBRX_cg.get_inst_coverage()), UVM_NONE)
    `uvm_info(get_type_name(), "==================================================", UVM_NONE)
  endfunction : report_phase

endclass : Sync_fifo_SBRX_subscriber

`endif // SYNC_FIFO_SBRX_SUBSCRIBER_SVH
