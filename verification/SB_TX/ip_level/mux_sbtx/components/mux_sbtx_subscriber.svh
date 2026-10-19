`ifndef MUX_SBTX_SUBSCRIBER_SVH
`define MUX_SBTX_SUBSCRIBER_SVH

class mux_sbtx_subscriber extends uvm_subscriber #(mux_sbtx_sequence_item);
  `uvm_component_utils(mux_sbtx_subscriber)
  mux_sbtx_sequence_item item;

  covergroup cg_mux;
    option.per_instance = 1;

    // Cover Select signal & transitions
    cp_sel: coverpoint item.Mux_Sel {
      bins sel_0      = {0};
      bins sel_1      = {1};
      bins toggle_0_1 = (0 => 1);
      bins toggle_1_0 = (1 => 0);
    }

    // Cover IN_0 corners and ranges
    cp_in0: coverpoint item.IN_0 {
      bins all_zeros   = {5'h00};
      bins all_ones    = {5'h1F};
      bins alt_10101   = {5'h15};
      bins alt_01010   = {5'h0A};
      bins low_range   = {[5'h01:5'h0F]} with (item != 5'h0A);
      bins high_range  = {[5'h10:5'h1E]} with (item != 5'h15);
    }

    // Cover IN_1 corners and ranges
    cp_in1: coverpoint item.IN_1 {
      bins all_zeros   = {5'h00};
      bins all_ones    = {5'h1F};
      bins alt_10101   = {5'h15};
      bins alt_01010   = {5'h0A};
      bins low_range   = {[5'h01:5'h0F]} with (item != 5'h0A);
      bins high_range  = {[5'h10:5'h1E]} with (item != 5'h15);
    }

    // Cover Output to ensure all output states are observed
    cp_out: coverpoint item.OUT {
      bins all_zeros   = {5'h00};
      bins all_ones    = {5'h1F};
      bins alt_patterns = {5'h15, 5'h0A};
      bins others      = default;
    }

    // Cross Coverage: Verify both IN_0 and IN_1 bins are exercised under both Mux_Sel states
    cx_sel_in0: cross cp_sel, cp_in0 {
      ignore_bins ignore_trans = binsof(cp_sel.toggle_0_1) || binsof(cp_sel.toggle_1_0);
    }
    cx_sel_in1: cross cp_sel, cp_in1 {
      ignore_bins ignore_trans = binsof(cp_sel.toggle_0_1) || binsof(cp_sel.toggle_1_0);
    }
  endgroup
  
  function new(string name = "mux_subscriber", uvm_component parent = null);
    super.new(name, parent);
    cg_mux = new();
  endfunction

  virtual function void write(mux_sbtx_sequence_item t);
    item = t;
    cg_mux.sample();
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("COV_REPORT", $sformatf("Overall Functional Coverage: %0.2f%%", cg_mux.get_inst_coverage()), UVM_LOW)
  endfunction

endclass
`endif // MUX_SBTX_SUBSCRIBER_SVH
