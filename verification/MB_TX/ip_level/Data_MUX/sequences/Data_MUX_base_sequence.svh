`ifndef DATA_MUX_BASE_SEQUENCE_SVH
`define DATA_MUX_BASE_SEQUENCE_SVH

class Data_MUX_base_sequence extends uvm_sequence #(Data_MUX_sequence_item);
  `uvm_object_utils(Data_MUX_base_sequence)
  `uvm_declare_p_sequencer(Data_MUX_sequencer)

  int num_txns = 20;

  function new(string name = "Data_MUX_base_sequence");
    super.new(name);
  endfunction

  task body();
    Data_MUX_sequence_item req;
    
    repeat (num_txns) begin
      req = Data_MUX_sequence_item::type_id::create("req");
      start_item(req);
      assert(req.randomize()) else `uvm_fatal("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

  endtask
endclass

`endif // DATA_MUX_BASE_SEQUENCE_SVH
