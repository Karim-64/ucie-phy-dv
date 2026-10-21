`ifndef PACKET_BUFFER_SBRX_BASE_SEQUENCE_SVH
`define PACKET_BUFFER_SBRX_BASE_SEQUENCE_SVH

class Packet_buffer_SBRX_base_sequence extends uvm_sequence #(Packet_buffer_SBRX_sequence_item);
  `uvm_object_utils(Packet_buffer_SBRX_base_sequence)

  function new(string name = "Packet_buffer_SBRX_base_sequence");
    super.new(name);
  endfunction

  task body();
  endtask

  function void cfg(Packet_buffer_SBRX_sequence_item it,
                    bit rst = 0, bit bal = 0, bit rdh = 0, bit wrh = 0, bit wdata = 1);
    it.c_rst.constraint_mode(rst);
    it.c_balanced.constraint_mode(bal);
    it.c_rd_heavy.constraint_mode(rdh);
    it.c_wr_heavy.constraint_mode(wrh);
    it.c_wr_data.constraint_mode(wdata);
  endfunction
endclass

`endif // PACKET_BUFFER_SBRX_BASE_SEQUENCE_SVH
