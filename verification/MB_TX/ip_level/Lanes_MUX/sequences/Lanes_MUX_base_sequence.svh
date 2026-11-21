`ifndef LANES_MUX_BASE_SEQUENCE_SVH
`define LANES_MUX_BASE_SEQUENCE_SVH

class Lanes_MUX_base_sequence extends uvm_sequence #(Lanes_MUX_sequence_item);
  `uvm_object_utils(Lanes_MUX_base_sequence)
  `uvm_declare_p_sequencer(Lanes_MUX_sequencer)

  Lanes_MUX_corner_sequence crnr_seq;
  Lanes_MUX_isolation_sequence iso_seq;
  Lanes_MUX_rand_sequence rand_seq;

  function new(string name = "Lanes_MUX_base_sequence");
    super.new(name);
  endfunction

  task pre_body;
      crnr_seq = Lanes_MUX_corner_sequence::type_id::create("crnr_seq");
      iso_seq = Lanes_MUX_isolation_sequence::type_id::create("iso_seq");
      rand_seq = Lanes_MUX_rand_sequence::type_id::create("rand_seq");
  endtask

  task body();
    crnr_seq.start (p_sequencer);
    iso_seq.start (p_sequencer);
    rand_seq.start (p_sequencer);
  endtask
endclass

`endif // LANES_MUX_BASE_SEQUENCE_SVH
