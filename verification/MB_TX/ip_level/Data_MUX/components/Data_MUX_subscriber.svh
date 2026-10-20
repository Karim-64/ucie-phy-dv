`ifndef DATA_MUX_SUBSCRIBER_SVH
`define DATA_MUX_SUBSCRIBER_SVH

class Data_MUX_subscriber extends uvm_subscriber #(Data_MUX_sequence_item);
  `uvm_component_utils(Data_MUX_subscriber)

  // Handle to the transaction currently being sampled.
  Data_MUX_sequence_item cov_tr;

  covergroup Data_MUX_cg;
    option.per_instance = 1;

    cp_IN_0: coverpoint cov_tr.IN_0{
      bins zero = { {64{8'h00}} };
      bins ones = { {64{8'hFF}} };
      bins alternating = {{64{8'hAA}}, {64{8'h55}}};
    }
    cp_IN_1: coverpoint cov_tr.IN_1{
      bins zero = { {64{8'h00}} };
      bins ones = { {64{8'hFF}} };
      bins alternating = {{64{8'hAA}}, {64{8'h55}}};
    }
    cp_SEL_5: coverpoint cov_tr.SEL_5{
      bins sel0 = {1'b0};
      bins sel1 = {1'b1};
      bins sel_toggle01 = (0 => 1);
      bins sel_toggle10 = (1 => 0);
    }
    cp_OUT: coverpoint cov_tr.OUT{
      bins zero = { {64{8'h00}} };
      bins ones = { {64{8'hFF}} };
      bins alternating = {{64{8'hAA}}, {64{8'h55}}};
    }

  endgroup : Data_MUX_cg

  function new(string name = "Data_MUX_subscriber", uvm_component parent = null);
    super.new(name, parent);
    Data_MUX_cg = new();
  endfunction : new

  function void write(Data_MUX_sequence_item t);
    if (t == null) begin
      `uvm_error("DATA_MUX_COV", "Received a null transaction")
      return;
    end
    cov_tr = t;
    Data_MUX_cg.sample();
  endfunction : write

endclass : Data_MUX_subscriber

`endif // DATA_MUX_SUBSCRIBER_SVH
