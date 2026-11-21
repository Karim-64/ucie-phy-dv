`ifndef PE_SBTX_D2D_BASE_SEQ_SVH
`define PE_SBTX_D2D_BASE_SEQ_SVH

class pe_sbtx_D2D_base_seq extends uvm_sequence#(pe_sbtx_D2D_sequence_item);
  `uvm_object_utils(pe_sbtx_D2D_base_seq)
  `uvm_declare_p_sequencer(pe_sbtx_D2D_sequencer)

  function new(string name = "pe_sbtx_D2D_base_seq");
    super.new(name);
  endfunction

  // Helper task to drive a single D2D cycle and notify the D2D monitor
  virtual task drive_d2d_item(logic rst_n = 1'b1, logic en = '0, logic data_marker = '0, logic comp_marker = '0, logic [DATA_WIDTH-1:0] data = '0);
    pe_sbtx_D2D_sequence_item m_item;
    logic _rst_n = rst_n;
    logic _en = en;
    logic _data_marker = data_marker;
    logic _comp_marker = comp_marker;
    logic [DATA_WIDTH-1:0] _data = data;

    `uvm_do_with(m_item, {
      m_item.rst_n == _rst_n;
      m_item.en == _en;
      m_item.data_marker == _data_marker;
      m_item.comp_marker == _comp_marker;
      m_item.data == _data;
    })
    p_sequencer.seqr_aport.write(m_item);
  endtask

  // Helper task to drive N idle cycles on the D2D interface
  virtual task drive_d2d_idle(int cycles = 1);
    repeat (cycles) begin
      drive_d2d_item();
    end
  endtask

  virtual task body();
    drive_d2d_idle(1);
  endtask
endclass

`endif // PE_SBTX_D2D_BASE_SEQ_SVH
