`ifndef DEMUX_SUBSCRIBER_SVH
`define DEMUX_SUBSCRIBER_SVH

class demux_subscriber extends uvm_subscriber #(demux_sequence_item);
  `uvm_component_utils(demux_subscriber)

  demux_sequence_item item;

  covergroup cg_demux;
    option.per_instance = 1;

    // Select line state coverage
    cp_sel: coverpoint item.SEL_4 {
      bins path_0 = {1'b0};
      bins path_1 = {1'b1};
    }

    // Select line dynamic switching transitions
    cp_sel_trans: coverpoint item.SEL_4 {
      bins toggle_0_to_1 = (1'b0 => 1'b1);
      bins toggle_1_to_0 = (1'b1 => 1'b0);
      bins hold_0        = (1'b0 => 1'b0);
      bins hold_1        = (1'b1 => 1'b1);
    }

    // Data pattern inspection (evaluated directly from actual payload)
    cp_data_type: coverpoint item.lp_data {
      bins all_zeros   = {512'h0};
      bins all_ones    = {{512{1'b1}}};
      bins alt_aa      = {{64{8'hAA}}};
      bins alt_55      = {{64{8'h55}}};
      bins misc_random = default;
    }

    // Boundary byte checks (LSB byte 0 and MSB byte 63)
    cp_byte_0: coverpoint item.lp_data[0] {
      bins zero = {8'h00};
      bins ones = {8'hFF};
      bins aa   = {8'hAA};
      bins b55  = {8'h55};
      bins misc = default;
    }

    cp_byte_63: coverpoint item.lp_data[63] {
      bins zero = {8'h00};
      bins ones = {8'hFF};
      bins aa   = {8'hAA};
      bins b55  = {8'h55};
      bins misc = default;
    }

    // Cross Coverage: Verify every data corner case is routed across both paths
    cx_sel_x_byte0:  cross cp_sel, cp_byte_0;
    cx_sel_x_byte63: cross cp_sel, cp_byte_63;
  endgroup

  function new(string name = "demux_subscriber", uvm_component parent = null);
    super.new(name, parent);
    cg_demux = new();
  endfunction

  virtual function void write(demux_sequence_item t);
    item = t;
    cg_demux.sample();
  endfunction

endclass

`endif // DEMUX_SUBSCRIBER_SVH
