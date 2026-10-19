`ifndef DMUX_1X4_SUBSCRIBER_SVH
`define DMUX_1X4_SUBSCRIBER_SVH

class DMUX_1x4_subscriber extends uvm_component;
  `uvm_component_utils(DMUX_1x4_subscriber)

  // Handle to the transaction currently being sampled
  DMUX_1x4_sequence_item cov_tr;
  uvm_analysis_export #(DMUX_1x4_sequence_item) exp;
  uvm_tlm_analysis_fifo #(DMUX_1x4_sequence_item) fifo;

  // ---------------------------------------------------------------------------
  // Functional Coverage Group
  // Mapped directly to the constraints in DMUX_1x4_sequence_item.svh:
  //   - normal
  //   - consecutive_zeros
  //   - consecutive_ones
  //   - toogles
  //   - walking_one
  //   - walking_zeros
  // ---------------------------------------------------------------------------
  covergroup DMUX_1x4_cg;
    option.per_instance = 1;
    option.name = "DMUX_1x4_Functional_Coverage";

    // -------------------------------------------------------------------------
    // 1. Destination Select Coverage (cp_sel)
    // -------------------------------------------------------------------------
    cp_sel: coverpoint cov_tr.sel {
      bins ch0 = {2'b00};
      bins ch1 = {2'b01};
      bins ch2 = {2'b10};
      bins ch3 = {2'b11};
      // Dynamic switching across consecutive channels
      bins sel_transitions[] = (2'b00, 2'b01, 2'b10, 2'b11 => 2'b00, 2'b01, 2'b10, 2'b11);
    }

    // -------------------------------------------------------------------------
    // 2. Raw Data Corner Values Coverage (cp_din_raw)
    // -------------------------------------------------------------------------
    cp_din_raw: coverpoint cov_tr.din {
      bins all_zeros = {'0};
      bins all_ones  = {'1, {(DATA_WIDTH-1){1'b1}}};
      bins toggle_10 = {{((DATA_WIDTH+1)/2){2'b10}}};
      bins toggle_01 = {{((DATA_WIDTH+1)/2){2'b01}}};
      bins random_data = default;
    }

    // -------------------------------------------------------------------------
    // 3. Bit Weight / Hamming Weight Coverage ($countones)
    // -------------------------------------------------------------------------
    cp_countones: coverpoint $countones(cov_tr.din) {
      bins zero_ones  = {0};                        // walking_zeros & consecutive_zeros
      bins single_one = {1};                        // walking_one
      bins all_ones   = {DATA_WIDTH, DATA_WIDTH-1}; // consecutive_ones
      bins mid_range  = default;                    // normal random
    }
    
    // -------------------------------------------------------------------------
    // 6. Active Output Channel Verification
    // -------------------------------------------------------------------------
    cp_d0_active: coverpoint cov_tr.d0 iff (cov_tr.sel == 2'b00) {
      bins zero     = {'0};
      bins all_ones = {'1, {(DATA_WIDTH-1){1'b1}}};
      bins active_data = default;
    }

    cp_d1_active: coverpoint cov_tr.d1 iff (cov_tr.sel == 2'b01) {
      bins zero     = {'0};
      bins all_ones = {'1, {(DATA_WIDTH-1){1'b1}}};
      bins active_data = default;
    }

    cp_d2_active: coverpoint cov_tr.d2 iff (cov_tr.sel == 2'b10) {
      bins zero     = {'0};
      bins all_ones = {'1, {(DATA_WIDTH-1){1'b1}}};
      bins active_data = default;
    }

    cp_d3_active: coverpoint cov_tr.d3 iff (cov_tr.sel == 2'b11) {
      bins zero     = {'0};
      bins all_ones = {'1, {(DATA_WIDTH-1){1'b1}}};
      bins active_data = default;
    }

    // -------------------------------------------------------------------------
    // 7. Inactive Channel Isolation (Must remain 0 when unselected)
    // -------------------------------------------------------------------------
    cp_d0_inactive: coverpoint cov_tr.d0 iff (cov_tr.sel != 2'b00) {
      bins idle_zero = {'0};
    }

    cp_d1_inactive: coverpoint cov_tr.d1 iff (cov_tr.sel != 2'b01) {
      bins idle_zero = {'0};
    }

    cp_d2_inactive: coverpoint cov_tr.d2 iff (cov_tr.sel != 2'b10) {
      bins idle_zero = {'0};
    }

    cp_d3_inactive: coverpoint cov_tr.d3 iff (cov_tr.sel != 2'b11) {
      bins idle_zero = {'0};
    }

  endgroup : DMUX_1x4_cg

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------
  function new(string name = "DMUX_1x4_subscriber", uvm_component parent = null);
    super.new(name, parent);
    exp   = new("exp", this);
    fifo  = new("fifo", this);
    exp.connect(fifo.analysis_export);
    DMUX_1x4_cg = new();
  endfunction : new

  // ---------------------------------------------------------------------------
  // Run Phase - fetch transactions from FIFO
  // ---------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    DMUX_1x4_sequence_item t;
    super.run_phase(phase);
    forever begin
      fifo.get(t);
      sample_item(t);
    end
  endtask

  // ---------------------------------------------------------------------------
  // Sample Method
  // ---------------------------------------------------------------------------
  function void sample_item(DMUX_1x4_sequence_item t);
    if (t == null) begin
      `uvm_error("DMUX_1X4_COV", "Received a null transaction in DMUX_1x4_subscriber")
      return;
    end
    cov_tr = t;
    DMUX_1x4_cg.sample();
  endfunction

  // ---------------------------------------------------------------------------
  // Report Phase - summarize coverage results in simulation log
  // ---------------------------------------------------------------------------
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("COV_REPORT", "============================================================", UVM_NONE)
    `uvm_info("COV_REPORT", "              DMUX_1x4 FUNCTIONAL COVERAGE REPORT           ", UVM_NONE)
    `uvm_info("COV_REPORT", "============================================================", UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf(" Total Coverage Achieved: %0.2f %%", DMUX_1x4_cg.get_inst_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", "============================================================", UVM_NONE)
  endfunction : report_phase

endclass : DMUX_1x4_subscriber

`endif // DMUX_1X4_SUBSCRIBER_SVH
