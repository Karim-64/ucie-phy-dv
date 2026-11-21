`ifndef DEMUX_SBTX_BASE_SEQUENCE_SVH
`define DEMUX_SBTX_BASE_SEQUENCE_SVH

class demux_SBTX_base_sequence extends uvm_sequence #(demux_SBTX_sequence_item);
  `uvm_object_utils(demux_SBTX_base_sequence)
  `uvm_declare_p_sequencer(demux_SBTX_sequencer)

  function new(string name = "demux_SBTX_base_sequence");
    super.new(name);
  endfunction

  task body();
    demux_SBTX_sequence_item seq_item;
    repeat(200) begin
      seq_item = demux_SBTX_sequence_item::type_id::create("seq_item");
      start_item(seq_item);
      assert (seq_item.randomize());
      finish_item(seq_item);
      p_sequencer.seqr_aport.write(seq_item);
    end
  endtask
endclass

`endif // DEMUX_SBTX_BASE_SEQUENCE_SVH
