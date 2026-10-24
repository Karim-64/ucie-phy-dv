`ifndef SYNCHRONIZER_SBRX_SUBSCRIBER_SVH
`define SYNCHRONIZER_SBRX_SUBSCRIBER_SVH

class Synchronizer_SBRX_subscriber extends uvm_subscriber #(Synchronizer_SBRX_sequence_item);
  `uvm_component_utils(Synchronizer_SBRX_subscriber)

  // Handle to the transaction currently being sampled.
  Synchronizer_SBRX_sequence_item cov_tr;

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
  covergroup Synchronizer_SBRX_cg;
    option.per_instance = 1;

    rst_n_cp: coverpoint cov_tr.rst_n {
      bins LOW  = {0};
      bins HIGH = {1};
    }
    signal_src_cp: coverpoint cov_tr.signal_src {
        bins LOW    = {0};
        bins HIGH   = {1};
        bins TOGGLE = (0 => 1), (1 => 0);
    }

    signal_dst_cp: coverpoint cov_tr.signal_dst {
        bins LOW    = {0};
        bins HIGH   = {1};
        bins TOGGLE = (0 => 1), (1 => 0);
    }

  endgroup : Synchronizer_SBRX_cg

  function new(string name = "Synchronizer_SBRX_subscriber", uvm_component parent = null);
    super.new(name, parent);
    Synchronizer_SBRX_cg = new();
  endfunction : new

  function void write(Synchronizer_SBRX_sequence_item t);
    if (t == null) begin
      `uvm_error("SYNCHRONIZER_SBRX_COV", "Received a null transaction")
      return;
    end
    cov_tr = t;
    Synchronizer_SBRX_cg.sample();
  endfunction : write

endclass : Synchronizer_SBRX_subscriber

`endif // SYNCHRONIZER_SBRX_SUBSCRIBER_SVH
