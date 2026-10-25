`ifndef LANES_MUX_RAND_SEQUENCE_SVH
`define LANES_MUX_RAND_SEQUENCE_SVH

class Lanes_MUX_rand_sequence extends uvm_sequence #(Lanes_MUX_sequence_item);
  `uvm_object_utils(Lanes_MUX_rand_sequence)
  `uvm_declare_p_sequencer(Lanes_MUX_sequencer)

  function new(string name = "Lanes_MUX_rand_sequence");
    super.new(name);
  endfunction

  task body();
    // TODO: Implement sequence body
    Lanes_MUX_sequence_item req;
    for (int i = 0 ; i < 300 ; i++) begin
      req = Lanes_MUX_sequence_item::type_id::create("req");
      start_item(req);
      assert (req.randomize()) 
      else 
        `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end
  endtask
endclass

`endif // LANES_MUX_BASE_SEQUENCE_SVH
