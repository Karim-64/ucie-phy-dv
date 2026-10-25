`ifndef CLK_GATE_SBTX_SUBSCRIBER_SVH
`define CLK_GATE_SBTX_SUBSCRIBER_SVH

class clk_gate_sbtx_subscriber extends uvm_subscriber #(clk_gate_sbtx_sequence_item);
  `uvm_component_utils(clk_gate_sbtx_subscriber)

  // Handle to the transaction currently being sampled.
  clk_gate_sbtx_sequence_item cov_tr;

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
  covergroup clk_gate_sbtx_cg;
    option.per_instance = 1;

    cp_Load: coverpoint cov_tr.Load;
    cp_Enable: coverpoint cov_tr.Enable;
    cp_SBTX_CLK: coverpoint cov_tr.SBTX_CLK;
    cp_CLK: coverpoint cov_tr.CLK;
    cp_delay: coverpoint cov_tr.delay{
          bins valid_delay[4] = {[0 : 2*PULSE_WIDTH-1]};
    }

    cp_cross_out_clk: cross cp_Enable, cp_Load, cp_SBTX_CLK, cp_CLK{
      ignore_bins ignore_clk_low_sbtx_high = binsof(cp_CLK) intersect {0} && binsof(cp_SBTX_CLK) intersect {1};
    }
    // TODO: Add iff-gated coverpoints and cross coverage specific to your DUT
    // (e.g. operation x address, data-pattern classification on valid transfers).
  endgroup : clk_gate_sbtx_cg

  function new(string name = "clk_gate_sbtx_subscriber", uvm_component parent = null);
    super.new(name, parent);
    clk_gate_sbtx_cg = new();
  endfunction : new

  function void write(clk_gate_sbtx_sequence_item t);
    if (t == null) begin
      `uvm_error("CLK_GATE_SBTX_COV", "Received a null transaction")
      return;
    end
    cov_tr = t;
    clk_gate_sbtx_cg.sample();
  endfunction : write

endclass : clk_gate_sbtx_subscriber

`endif // CLK_GATE_SBTX_SUBSCRIBER_SVH
