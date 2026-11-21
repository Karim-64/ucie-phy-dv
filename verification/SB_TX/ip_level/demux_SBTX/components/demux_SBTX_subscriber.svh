`ifndef DEMUX_SBTX_SUBSCRIBER_SVH
`define DEMUX_SBTX_SUBSCRIBER_SVH

class demux_SBTX_subscriber extends uvm_subscriber #(demux_SBTX_sequence_item);
  `uvm_component_utils(demux_SBTX_subscriber)

  // Handle to the transaction currently being sampled.
  demux_SBTX_sequence_item cov_tr;

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
  localparam bit [DATA_WIDTH-1:0] ALL_ZEROS = {DATA_WIDTH{1'b0}};
  localparam bit [DATA_WIDTH-1:0] ALL_ONES  = {DATA_WIDTH{1'b1}};
  localparam bit [DATA_WIDTH-1:0] ALT_0101  = {(DATA_WIDTH/2){2'b01}};
  localparam bit [DATA_WIDTH-1:0] ALT_1010  = {(DATA_WIDTH/2){2'b10}};
  localparam bit [DATA_WIDTH-1:0] MID       = {1'b1, {(DATA_WIDTH-1){1'b0}}};

  covergroup demux_SBTX_cg;
    option.per_instance = 1;

    cp_din: coverpoint cov_tr.din {
      option.auto_bin_max = 16;
    }
    cp_sel: coverpoint cov_tr.sel {
      bins sel_0 = {2'b00};
      bins sel_1 = {2'b01};
      bins sel_2 = {2'b10};
      bins sel_3 = {2'b11};
    }
    cp_dout0: coverpoint cov_tr.dout0 {
      bins all_zeros    = {ALL_ZEROS};
      bins all_ones     = {ALL_ONES};
      bins alt_0101     = {ALT_0101};
      bins alt_1010     = {ALT_1010};
      bins low_range    = {[ALL_ZEROS + 1 : ALT_0101 - 1],
                           [ALT_0101  + 1 : MID - 1]};
      bins high_range   = {[MID        : ALT_1010 - 1],
                           [ALT_1010 + 1 : ALL_ONES - 1]};
    }
    cp_dout1: coverpoint cov_tr.dout1 {
      bins all_zeros    = {ALL_ZEROS};
      bins all_ones     = {ALL_ONES};
      bins alt_0101     = {ALT_0101};
      bins alt_1010     = {ALT_1010};
      bins low_range    = {[ALL_ZEROS + 1 : ALT_0101 - 1],
                           [ALT_0101  + 1 : MID - 1]};
      bins high_range   = {[MID        : ALT_1010 - 1],
                           [ALT_1010 + 1 : ALL_ONES - 1]};
    }
    cp_dout2: coverpoint cov_tr.dout2 {
      bins all_zeros    = {ALL_ZEROS};
      bins all_ones     = {ALL_ONES};
      bins alt_0101     = {ALT_0101};
      bins alt_1010     = {ALT_1010};
      bins low_range    = {[ALL_ZEROS + 1 : ALT_0101 - 1],
                           [ALT_0101  + 1 : MID - 1]};
      bins high_range   = {[MID        : ALT_1010 - 1],
                           [ALT_1010 + 1 : ALL_ONES - 1]};
    }
    cp_dout3: coverpoint cov_tr.dout3 {
      bins all_zeros    = {ALL_ZEROS};
      bins all_ones     = {ALL_ONES};
      bins alt_0101     = {ALT_0101};
      bins alt_1010     = {ALT_1010};
      bins low_range    = {[ALL_ZEROS + 1 : ALT_0101 - 1],
                           [ALT_0101  + 1 : MID - 1]};
      bins high_range   = {[MID        : ALT_1010 - 1],
                           [ALT_1010 + 1 : ALL_ONES - 1]};
    }

    cx_sel_dout0: cross cp_sel, cp_dout0 {
      ignore_bins not_selected = binsof(cp_sel) intersect {1, 2, 3} && !binsof(cp_dout0.all_zeros);
    }
    cx_sel_dout1: cross cp_sel, cp_dout1 {
      ignore_bins not_selected = binsof(cp_sel) intersect {0, 2, 3} && !binsof(cp_dout1.all_zeros);
    }
    cx_sel_dout2: cross cp_sel, cp_dout2 {
      ignore_bins not_selected = binsof(cp_sel) intersect {0, 1, 3} && !binsof(cp_dout2.all_zeros);
    }
    cx_sel_dout3: cross cp_sel, cp_dout3 {
      ignore_bins not_selected = binsof(cp_sel) intersect {0, 1, 2} && !binsof(cp_dout3.all_zeros);
    }
  endgroup : demux_SBTX_cg

  function new(string name = "demux_SBTX_subscriber", uvm_component parent = null);
    super.new(name, parent);
    demux_SBTX_cg = new();
  endfunction : new

  function void write(demux_SBTX_sequence_item t);
    if (t == null) begin
      `uvm_error("DEMUX_SBTX_COV", "Received a null transaction")
      return;
    end
    cov_tr = t;
    demux_SBTX_cg.sample();
  endfunction : write

endclass : demux_SBTX_subscriber

`endif // DEMUX_SBTX_SUBSCRIBER_SVH
