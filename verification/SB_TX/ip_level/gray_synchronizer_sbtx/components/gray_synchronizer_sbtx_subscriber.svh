`ifndef GRAY_SYNCHRONIZER_SBTX_SUBSCRIBER_SVH
`define GRAY_SYNCHRONIZER_SBTX_SUBSCRIBER_SVH

class gray_synchronizer_sbtx_subscriber extends uvm_subscriber #(gray_synchronizer_sbtx_sequence_item);
  `uvm_component_utils(gray_synchronizer_sbtx_subscriber)

  // Handle to the transaction currently being sampled.
  gray_synchronizer_sbtx_sequence_item cov_tr;

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
  covergroup gray_synchronizer_sbtx_cg;
    option.per_instance = 1;

    cp_RST_n: coverpoint cov_tr.RST_n {
      bins high = {1};
      bins low = {0};
      bins toggle_01 = (0=>1);
      bins toggle_10 = (1=>0);
    }
    cp_Async_Data: coverpoint cov_tr.Async_Data {
      option.auto_bin_max = 16;
    }
    cp_Sync_Data: coverpoint cov_tr.Sync_Data {
      option.auto_bin_max = 16;
    }

    cx_data_out: cross cp_Async_Data, cp_Sync_Data;

    // TODO: Add iff-gated coverpoints and cross coverage specific to your DUT
    // (e.g. operation x address, data-pattern classification on valid transfers).
  endgroup : gray_synchronizer_sbtx_cg

  function new(string name = "gray_synchronizer_sbtx_subscriber", uvm_component parent = null);
    super.new(name, parent);
    gray_synchronizer_sbtx_cg = new();
  endfunction : new

  function void write(gray_synchronizer_sbtx_sequence_item t);
    if (t == null) begin
      `uvm_error("GRAY_SYNCHRONIZER_SBTX_COV", "Received a null transaction")
      return;
    end
    cov_tr = t;
    gray_synchronizer_sbtx_cg.sample();
  endfunction : write

endclass : gray_synchronizer_sbtx_subscriber

`endif // GRAY_SYNCHRONIZER_SBTX_SUBSCRIBER_SVH
