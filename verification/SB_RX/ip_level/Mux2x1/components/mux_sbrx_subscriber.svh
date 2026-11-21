`ifndef MUX_SBRX_SUBSCRIBER_SVH
`define MUX_SBRX_SUBSCRIBER_SVH

class mux_sbrx_subscriber extends uvm_subscriber #(mux_sbrx_sequence_item);
  `uvm_component_utils(mux_sbrx_subscriber)
  mux_sbrx_sequence_item item;

  covergroup cg_mux;
    option.per_instance = 1;

    // Cover Select signal & transitions
    cp_sel: coverpoint item.sel {
      bins sel_0      = {0};
      bins sel_1      = {1};
      bins toggle_0_1 = (0 => 1);
      bins toggle_1_0 = (1 => 0);
    }

    // Cover in0 corners and ranges
    cp_in0: coverpoint item.in0 {
      bins all_zeros   = {5'h00};
      bins all_ones    = {5'h1F};
      bins alt_10101   = {5'h15};
      bins alt_01010   = {5'h0A};
      bins low_range   = {[5'h01:5'h0F]} with (item != 5'h0A);
      bins high_range  = {[5'h10:5'h1E]} with (item != 5'h15);
    }

    // Cover in1 corners and ranges
    cp_in1: coverpoint item.in1 {
      bins all_zeros   = {5'h00};
      bins all_ones    = {5'h1F};
      bins alt_10101   = {5'h15};
      bins alt_01010   = {5'h0A};
      bins low_range   = {[5'h01:5'h0F]} with (item != 5'h0A);
      bins high_range  = {[5'h10:5'h1E]} with (item != 5'h15);
    }

    // Cover Output to ensure all output states are observed
    cp_out: coverpoint item.out {
      bins all_zeros   = {5'h00};
      bins all_ones    = {5'h1F};
      bins alt_patterns = {5'h15, 5'h0A};
      bins others      = default;
    }

    // Cross Coverage: Verify both in0 and in1 bins are exercised under both sel states
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

  virtual function void write(mux_sbrx_sequence_item t);
    item = t;
    cg_mux.sample();
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("COV_REPORT", $sformatf("Overall Functional Coverage: %0.2f%%", cg_mux.get_inst_coverage()), UVM_LOW)
  endfunction

endclass
`endif // MUX_SBRX_SUBSCRIBER_SVH
