`ifndef SERIALIZER_SUBSCRIBER_SVH
`define SERIALIZER_SUBSCRIBER_SVH

class Serializer_subscriber extends uvm_subscriber #(Serializer_sequence_item);
  `uvm_component_utils(Serializer_subscriber)

  // Handle to the transaction currently being sampled.
  Serializer_sequence_item cov_tr;


  covergroup Serializer_cg;
    option.per_instance = 1;

    cp_SER_EN: coverpoint cov_tr.SER_EN {
      bins disabled = {1'b0};
      bins enabled  = {1'b1};
    }
    cp_DATA_pattern: coverpoint cov_tr.DATA
    {
      bins all_zero          = {8'h00};
      bins all_one           = {8'hFF};
      bins alternating_01    = {8'h55};
      bins alternating_10    = {8'hAA};
      bins low_nibble_ones   = {8'h0F};
      bins high_nibble_ones  = {8'hF0};
      bins other             = default;
    }

    cp_SER_OUT: coverpoint cov_tr.SER_OUT {
      bins low  = {1'b0};
      bins high = {1'b1};
    }

  endgroup : Serializer_cg

  function new(string name = "Serializer_subscriber", uvm_component parent = null);
    super.new(name, parent);
    Serializer_cg = new();
  endfunction : new

  function void write(Serializer_sequence_item t);
    if (t == null) begin
      `uvm_error("SERIALIZER_COV", "Received a null transaction")
      return;
    end
    cov_tr = t;
    Serializer_cg.sample();
  endfunction : write

endclass : Serializer_subscriber

`endif // SERIALIZER_SUBSCRIBER_SVH
