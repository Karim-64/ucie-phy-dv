`ifndef PACKET_BUFFER_SBRX_HEAVY_WR_SEQUENCE_SVH
`define PACKET_BUFFER_SBRX_HEAVY_WR_SEQUENCE_SVH

class Packet_buffer_SBRX_heavy_wr_sequence extends Packet_buffer_SBRX_base_sequence;
  `uvm_object_utils(Packet_buffer_SBRX_heavy_wr_sequence)
  `uvm_declare_p_sequencer(Packet_buffer_SBRX_sequencer)

  Packet_buffer_SBRX_sequence_item seq_item;

  function new(string name = "Packet_buffer_SBRX_heavy_wr_sequence");
    super.new(name);
  endfunction

  task body();
    repeat(30) begin
      seq_item = Packet_buffer_SBRX_sequence_item::type_id::create("seq_item");
      cfg(.it(seq_item), .rst(1), .bal(0), .rdh(0), .wrh(1), .wdata(1));
      start_item(seq_item);
      assert(seq_item.randomize());
      finish_item(seq_item);
      p_sequencer.seqr_aport.write(seq_item);
    end
  endtask

endclass

`endif // PACKET_BUFFER_SBRX_HEAVY_WR_SEQUENCE_SVH
