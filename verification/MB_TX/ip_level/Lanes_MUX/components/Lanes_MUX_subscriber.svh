`ifndef LANES_MUX_SUBSCRIBER_SVH
`define LANES_MUX_SUBSCRIBER_SVH

class Lanes_MUX_lane_cov;
    int idx;

    covergroup Lanes_MUX_cg with function sample(bit [7:0] in0, bit [7:0] in1, bit sel, bit [7:0] out);
        
        option.per_instance = 1;

        cp_IN_0: coverpoint in0 {
            option.auto_bin_max = 8;
            bins zeros = {8'h00};
            bins maxs  = {8'hFF};
            bins corners = {8'h01, 8'hFE, 8'h80, 8'h7F};
            bins patterns_0101 = {8'h55};
            bins patterns_1010 = {8'hAA};
            bins low_range    = {[8'h02:8'h0F]};
            bins high_range   = {[8'hF0:8'hFD]};
            bins middle_range = {[8'h10:8'hEF]};
        }

        cp_IN_1: coverpoint in1 {
            option.auto_bin_max = 8;
            bins zeros = {8'h00};
            bins maxs  = {8'hFF};
            bins corners = {8'h01, 8'hFE, 8'h80, 8'h7F};
            bins patterns_0101 = {8'h55};
            bins patterns_1010 = {8'hAA};
            bins low_range    = {[8'h02:8'h0F]};
            bins high_range   = {[8'hF0:8'hFD]};
            bins middle_range = {[8'h10:8'hEF]};
        }

        cp_SEL_2: coverpoint sel {
            bins low  = {0};
            bins high = {1};
            bins toggle_0 = (0 => 1);
            bins toggle_1 = (1 => 0);
        }

        cp_OUT: coverpoint out {
            option.auto_bin_max = 8;
            bins zeros = {8'h00};
            bins maxs  = {8'hFF};
            bins corners = {8'h01, 8'hFE, 8'h80, 8'h7F};
            bins patterns_0101 = {8'h55};
            bins patterns_1010 = {8'hAA};
            bins low_range    = {[8'h02:8'h0F]};
            bins high_range   = {[8'hF0:8'hFD]};
            bins middle_range = {[8'h10:8'hEF]};
        }

        cx_sel_data_in0: cross cp_SEL_2, cp_IN_0;
        cx_sel_data_in1: cross cp_SEL_2, cp_IN_1;
        cx_sel_data_out: cross cp_SEL_2, cp_OUT;

    endgroup : Lanes_MUX_cg

    function new(int idx);
        this.idx = idx;
        Lanes_MUX_cg = new();                  
        Lanes_MUX_cg.set_inst_name($sformatf("lane_%0d", idx));
    endfunction

    function void sample(bit [7:0] in0, in1, bit sel, bit [7:0] out);
        Lanes_MUX_cg.sample(in0, in1, sel, out);
    endfunction
endclass

class Lanes_MUX_subscriber extends uvm_subscriber #(Lanes_MUX_sequence_item);
  `uvm_component_utils(Lanes_MUX_subscriber)

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
  Lanes_MUX_lane_cov cg [16];

  function new(string name = "Lanes_MUX_subscriber", uvm_component parent = null);
    super.new(name, parent);
    foreach (cg[i])
      cg[i] = new(i);
  endfunction : new

  function void write(Lanes_MUX_sequence_item t);
    if (t == null) begin
      `uvm_error("LANES_MUX_COV", "Received a null transaction")
      return;
    end
    foreach (cg[i])
      cg[i].sample(t.IN_0[i], t.IN_1[i], t.SEL_2, t.OUT[i]);

  endfunction : write

endclass : Lanes_MUX_subscriber

`endif // LANES_MUX_SUBSCRIBER_SVH
