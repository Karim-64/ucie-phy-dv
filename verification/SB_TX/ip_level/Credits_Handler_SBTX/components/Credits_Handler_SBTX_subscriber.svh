`ifndef CREDITS_HANDLER_SBTX_SUBSCRIBER_SVH
`define CREDITS_HANDLER_SBTX_SUBSCRIBER_SVH

class Credits_Handler_SBTX_subscriber extends uvm_subscriber #(Credits_Handler_SBTX_sequence_item);
  `uvm_component_utils(Credits_Handler_SBTX_subscriber)

  // Handle to the transaction currently being sampled.
  Credits_Handler_SBTX_sequence_item cov_tr;

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
  covergroup Credits_Handler_SBTX_cg;
    option.per_instance = 1;

    cp_rst_n: coverpoint cov_tr.rst_n;
    cp_comp_sent: coverpoint cov_tr.comp_sent;
    cp_UIE: coverpoint cov_tr.UIE;
    cp_credit: coverpoint cov_tr.credit;
    cp_D2D_phy_marker: coverpoint cov_tr.D2D_phy_marker;
    cp_data_marker: coverpoint cov_tr.data_marker;
    cp_comp_marker: coverpoint cov_tr.comp_marker;
    cp_pl_cfg_crd: coverpoint cov_tr.pl_cfg_crd;

    // TODO: Add iff-gated coverpoints and cross coverage specific to your DUT
    // (e.g. operation x address, data-pattern classification on valid transfers).
  endgroup : Credits_Handler_SBTX_cg

  function new(string name = "Credits_Handler_SBTX_subscriber", uvm_component parent = null);
    super.new(name, parent);
    Credits_Handler_SBTX_cg = new();
  endfunction : new

  function void write(Credits_Handler_SBTX_sequence_item t);
    if (t == null) begin
      `uvm_error("CREDITS_HANDLER_SBTX_COV", "Received a null transaction")
      return;
    end
    cov_tr = t;
    Credits_Handler_SBTX_cg.sample();
  endfunction : write

endclass : Credits_Handler_SBTX_subscriber

`endif // CREDITS_HANDLER_SBTX_SUBSCRIBER_SVH
