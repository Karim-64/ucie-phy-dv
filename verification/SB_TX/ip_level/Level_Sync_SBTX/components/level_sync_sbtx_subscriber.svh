`ifndef LEVEL_SYNC_SBTX_SUBSCRIBER_SVH
`define LEVEL_SYNC_SBTX_SUBSCRIBER_SVH

class level_sync_sbtx_subscriber extends uvm_subscriber #(level_sync_sbtx_sequence_item);
  `uvm_component_utils(level_sync_sbtx_subscriber)

  // Handle to the transaction currently being sampled.
  level_sync_sbtx_sequence_item cov_tr;

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
  covergroup level_sync_sbtx_cg;
    option.per_instance = 1;

    cp_RST_n: coverpoint cov_tr.RST_n;
    cp_Async_Signal: coverpoint cov_tr.Async_Signal;
    cp_Sync_Signal: coverpoint cov_tr.Sync_Signal;

    crp_rst_async: cross cp_RST_n, cp_Async_Signal;
  endgroup : level_sync_sbtx_cg

  function new(string name = "level_sync_sbtx_subscriber", uvm_component parent = null);
    super.new(name, parent);
    level_sync_sbtx_cg = new();
  endfunction : new

  function void write(level_sync_sbtx_sequence_item t);
    if (t == null) begin
      `uvm_error("LEVEL_SYNC_SBTX_COV", "Received a null transaction")
      return;
    end
    cov_tr = t;
    level_sync_sbtx_cg.sample();
  endfunction : write

endclass : level_sync_sbtx_subscriber

`endif // LEVEL_SYNC_SBTX_SUBSCRIBER_SVH
