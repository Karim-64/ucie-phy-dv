`ifndef PACKET_BUFFER_SBRX_RST_SEQUENCE_SVH
`define PACKET_BUFFER_SBRX_RST_SEQUENCE_SVH

class Packet_buffer_SBRX_rst_sequence extends Packet_buffer_SBRX_base_sequence;
  `uvm_object_utils(Packet_buffer_SBRX_rst_sequence)
  `uvm_declare_p_sequencer(Packet_buffer_SBRX_sequencer)

  Packet_buffer_SBRX_sequence_item seq_item;

  function new(string name = "Packet_buffer_SBRX_rst_sequence");
    super.new(name);
  endfunction

  task body();
    repeat(1) begin
      seq_item = Packet_buffer_SBRX_sequence_item::type_id::create("seq_item");
      start_item(seq_item);
      seq_item.sys_rst = 0;
      seq_item.wr_en = 0;
      seq_item.rd_en = 0;
      seq_item.wr_data = '0;
      finish_item(seq_item);
      p_sequencer.seqr_aport.write(seq_item);
    end
  endtask

endclass

`endif // PACKET_BUFFER_SBRX_RST_SEQUENCE_SVH
