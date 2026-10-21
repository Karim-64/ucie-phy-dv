`ifndef PACKET_BUFFER_SBRX_ALTERNATE_SEQUENCE_SVH
`define PACKET_BUFFER_SBRX_ALTERNATE_SEQUENCE_SVH

class Packet_buffer_SBRX_alternate_sequence extends Packet_buffer_SBRX_base_sequence;
  `uvm_object_utils(Packet_buffer_SBRX_alternate_sequence)
  `uvm_declare_p_sequencer(Packet_buffer_SBRX_sequencer)

  Packet_buffer_SBRX_sequence_item seq_item;

  function new(string name = "Packet_buffer_SBRX_alternate_sequence");
    super.new(name);
  endfunction

  task body();
    seq_item = Packet_buffer_SBRX_sequence_item::type_id::create("seq_item");
    cfg(.it(seq_item), .rst(0), .bal(0), .rdh(0), .wrh(0), .wdata(0));
    start_item(seq_item);
    assert(seq_item.randomize());
    seq_item.sys_rst = 0;
    seq_item.wr_en = 0;
    seq_item.rd_en = 0;
    finish_item(seq_item);
    p_sequencer.seqr_aport.write(seq_item);

    repeat(10) begin
      seq_item = Packet_buffer_SBRX_sequence_item::type_id::create("seq_item");
      cfg(.it(seq_item), .rst(0), .bal(0), .rdh(0), .wrh(0), .wdata(1));
      start_item(seq_item);
      assert(seq_item.randomize());
      seq_item.sys_rst = 1;
      seq_item.wr_en = 1;
      seq_item.rd_en = 0;
      finish_item(seq_item);
      p_sequencer.seqr_aport.write(seq_item);
  
      seq_item = Packet_buffer_SBRX_sequence_item::type_id::create("seq_item");
      cfg(.it(seq_item), .rst(0), .bal(0), .rdh(0), .wrh(0), .wdata(1));
      start_item(seq_item);
      assert(seq_item.randomize());
      seq_item.sys_rst = 1;
      seq_item.wr_en = 0;
      seq_item.rd_en = 1;
      finish_item(seq_item);
      p_sequencer.seqr_aport.write(seq_item);
    end
  endtask

endclass

`endif // PACKET_BUFFER_SBRX_ALTERNATE_SEQUENCE_SVH
