`ifndef VLD_MUX_BASE_SEQUENCE_SVH
`define VLD_MUX_BASE_SEQUENCE_SVH

class VLD_MUX_base_sequence extends uvm_sequence #(VLD_MUX_sequence_item);
  `uvm_object_utils(VLD_MUX_base_sequence)
  `uvm_declare_p_sequencer(VLD_MUX_sequencer)

  function new(string name = "VLD_MUX_base_sequence");
    super.new(name);
  endfunction

  task body();
    VLD_MUX_sequence_item seq_item;

    repeat(400) begin
      seq_item = VLD_MUX_sequence_item::type_id::create("seq_item");
      start_item(seq_item);
      assert(seq_item.randomize());
      finish_item(seq_item);
      p_sequencer.seqr_aport.write(seq_item);
    end
  endtask
endclass

`endif // VLD_MUX_BASE_SEQUENCE_SVH
