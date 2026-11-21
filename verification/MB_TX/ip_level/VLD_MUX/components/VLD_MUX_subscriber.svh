`ifndef VLD_MUX_SUBSCRIBER_SVH
`define VLD_MUX_SUBSCRIBER_SVH

class VLD_MUX_subscriber extends uvm_subscriber #(VLD_MUX_sequence_item);
  `uvm_component_utils(VLD_MUX_subscriber)

  // Handle to the transaction currently being sampled.
  VLD_MUX_sequence_item cov_tr;

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
  covergroup VLD_MUX_cg;
    option.per_instance = 1;

    cp_IN_0: coverpoint cov_tr.IN_0 {
      bins all_zeros    = {8'h00};
      bins all_ones     = {8'hFF};
      bins alt_01010101 = {8'h55};
      bins alt_10101010 = {8'hAA};
      bins low_range    = {[8'h01:8'h7F]} with (item != 8'h55);
      bins high_range   = {[8'h80:8'hFE]} with (item != 8'hAA);
    }

    cp_IN_1: coverpoint cov_tr.IN_1 {
      bins all_zeros    = {8'h00};
      bins all_ones     = {8'hFF};
      bins alt_01010101 = {8'h55};
      bins alt_10101010 = {8'hAA};
      bins low_range    = {[8'h01:8'h7F]} with (item != 8'h55);
      bins high_range   = {[8'h80:8'hFE]} with (item != 8'hAA);
    }

    cp_IN_2: coverpoint cov_tr.IN_2 {
      bins all_zeros    = {8'h00};
      bins all_ones     = {8'hFF};
      bins alt_01010101 = {8'h55};
      bins alt_10101010 = {8'hAA};
      bins low_range    = {[8'h01:8'h7F]} with (item != 8'h55);
      bins high_range   = {[8'h80:8'hFE]} with (item != 8'hAA);
    }

    cp_IN_3: coverpoint cov_tr.IN_3 {
      bins all_zeros    = {8'h00};
      bins all_ones     = {8'hFF};
      bins alt_01010101 = {8'h55};
      bins alt_10101010 = {8'hAA};
      bins low_range    = {[8'h01:8'h7F]} with (item != 8'h55);
      bins high_range   = {[8'h80:8'hFE]} with (item != 8'hAA);
    }

    cp_SEL_1: coverpoint cov_tr.SEL_1 {
      bins sel_0 = {2'b00};
      bins sel_1 = {2'b01};
      bins sel_2 = {2'b10};
      bins sel_3 = {2'b11};
    }

    cp_OUT: coverpoint cov_tr.OUT {
      bins all_zeros    = {8'h00};
      bins all_ones     = {8'hFF};
      bins alt_01010101 = {8'h55};
      bins alt_10101010 = {8'hAA};
      bins low_range    = {[8'h01:8'h7F]} with (item != 8'h55);
      bins high_range   = {[8'h80:8'hFE]} with (item != 8'hAA);
    }

    // ---------------- Crosses ----------------
    cx_sel_in0 : cross cp_SEL_1, cp_IN_0;
    cx_sel_in1 : cross cp_SEL_1, cp_IN_1;
    cx_sel_in2 : cross cp_SEL_1, cp_IN_2;
    cx_sel_in3 : cross cp_SEL_1, cp_IN_3;

  endgroup : VLD_MUX_cg

  function new(string name = "VLD_MUX_subscriber", uvm_component parent = null);
    super.new(name, parent);
    VLD_MUX_cg = new();
  endfunction : new

  function void write(VLD_MUX_sequence_item t);
    if (t == null) begin
      `uvm_error("VLD_MUX_COV", "Received a null transaction")
      return;
    end
    cov_tr = t;
    VLD_MUX_cg.sample();
  endfunction : write

endclass : VLD_MUX_subscriber

`endif // VLD_MUX_SUBSCRIBER_SVH
