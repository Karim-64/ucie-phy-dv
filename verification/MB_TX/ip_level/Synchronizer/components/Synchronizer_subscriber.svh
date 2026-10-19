`ifndef SYNCHRONIZER_SUBSCRIBER_SVH
`define SYNCHRONIZER_SUBSCRIBER_SVH

class Synchronizer_subscriber extends uvm_component;
  `uvm_component_utils(Synchronizer_subscriber)
  uvm_analysis_export #(Synchronizer_sequence_item) exp;
  uvm_tlm_analysis_fifo #(Synchronizer_sequence_item) fifo;

  // Handle to the transaction currently being sampled.
  Synchronizer_sequence_item cov_tr;

  // ---------------------------------------------------------------------
  // Functional Coverage
  //
  // One coverpoint per interface signal, sampling its raw value with
  // default binning (auto_bin_max for multi-bit fields). This is
  // intentionally semantics-free: it does NOT know which combinations
  // matter for your DUT (e.g. "only sample address on a valid read").
  // Add `iff` gates and `cross` coverage by hand for anything that
  // needs DUT-specific context.
  // ---------------------------------------------------------------------
  covergroup Synchronizer_cg;
    option.per_instance = 1;

    cp_rst_n: coverpoint cov_tr.rst_n;
    cp_signal_src: coverpoint cov_tr.signal_src;
    cp_signal_dst: coverpoint cov_tr.signal_dst;

    // TODO: Add iff-gated coverpoints and cross coverage specific to your DUT
    // (e.g. operation x address, data-pattern classification on valid transfers).
  endgroup : Synchronizer_cg

  function new(string name = "Synchronizer_subscriber", uvm_component parent = null);
    super.new(name, parent);
    exp   = new("exp", this);
    fifo  = new("fifo", this);
    exp.connect(fifo.analysis_export);
    Synchronizer_cg = new();
  endfunction : new

  task run_phase(uvm_phase phase);
    Synchronizer_sequence_item t;
    super.run_phase(phase);
    forever begin
      fifo.get(t);
      sample_item(t);
    end
  endtask

  function void sample_item(Synchronizer_sequence_item t);
    if (t == null) begin
      `uvm_error("SYNCHRONIZER_COV", "Received a null transaction")
      return;
    end
    cov_tr = t;
    Synchronizer_cg.sample();
  endfunction

  // ---------------------------------------------------------------------------
  // Report Phase - summarize functional coverage percentage
  // ---------------------------------------------------------------------------
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("COV_REPORT", "============================================================", UVM_NONE)
    `uvm_info("COV_REPORT", "           SYNCHRONIZER FUNCTIONAL COVERAGE REPORT          ", UVM_NONE)
    `uvm_info("COV_REPORT", "============================================================", UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf(" Total Coverage Achieved: %0.2f %%", Synchronizer_cg.get_inst_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", "============================================================", UVM_NONE)
  endfunction : report_phase

endclass : Synchronizer_subscriber

`endif // SYNCHRONIZER_SUBSCRIBER_SVH
