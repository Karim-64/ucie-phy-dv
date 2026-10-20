`ifndef DEMUX_SUBSCRIBER_SVH
`define DEMUX_SUBSCRIBER_SVH

class DEMUX_subscriber extends uvm_subscriber #(DEMUX_sequence_item);
  `uvm_component_utils(DEMUX_subscriber)

  // Handle to the transaction currently being sampled.
  DEMUX_sequence_item cov_tr;

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
  covergroup DEMUX_cg;
    option.per_instance = 1;

    cp_lp_data: coverpoint cov_tr.lp_data {
      option.auto_bin_max = 2;
    }
    cp_SEL_4: coverpoint cov_tr.SEL_4{
      bins SEL_0 = {0};
      bins SEL_1 = {1};
    }
    cp_lp_data_0: coverpoint cov_tr.lp_data_0 {
      option.auto_bin_max = 2;
    }
    cp_lp_data_1: coverpoint cov_tr.lp_data_1 {
      option.auto_bin_max = 2;
    }

    cross_sel_data: cross cp_SEL_4, cp_lp_data_0, cp_lp_data_1{ 
      option.cross_auto_bin_max = 0;
      bins SEL_0_lp_data_1 = binsof(cp_SEL_4.SEL_0) && binsof(cp_lp_data_1) intersect {0};
      bins SEL_1_lp_data_0 = binsof(cp_SEL_4.SEL_1) && binsof(cp_lp_data_0) intersect {0};
      bins SEL_0_lp_data_0 = binsof(cp_SEL_4.SEL_0) && binsof(cp_lp_data_0);
      bins SEL_1_lp_data_1 = binsof(cp_SEL_4.SEL_1) && binsof(cp_lp_data_1);
    }

  endgroup : DEMUX_cg

  function new(string name = "DEMUX_subscriber", uvm_component parent = null);
    super.new(name, parent);
    DEMUX_cg = new();
  endfunction : new

  function void write(DEMUX_sequence_item t);
    if (t == null) begin
      `uvm_error("DEMUX_COV", "Received a null transaction")
      return;
    end
    cov_tr = t;
    DEMUX_cg.sample();
  endfunction : write

endclass : DEMUX_subscriber

`endif // DEMUX_SUBSCRIBER_SVH
