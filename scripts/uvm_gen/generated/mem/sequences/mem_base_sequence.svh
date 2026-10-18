`ifndef MEM_BASE_SEQUENCE_SVH
`define MEM_BASE_SEQUENCE_SVH

class mem_base_sequence extends uvm_sequence #(mem_sequence_item);
  `uvm_object_utils(mem_base_sequence)
  `uvm_declare_p_sequencer(mem_sequencer)

  function new(string name = "mem_base_sequence");
    super.new(name);
  endfunction

  task body();
    // TODO: Implement sequence body
    // e.g. req = mem_sequence_item::type_id::create("req");
    // start_item(req);
    // if (!req.randomize() with { ... }) `uvm_error("SEQ", "Randomization failed")
    // finish_item(req);
  endtask
endclass

`endif // MEM_BASE_SEQUENCE_SVH
