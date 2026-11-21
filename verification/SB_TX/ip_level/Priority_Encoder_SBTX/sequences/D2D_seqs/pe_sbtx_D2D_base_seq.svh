`ifndef PE_SBTX_D2D_BASE_SEQ_SVH
`define PE_SBTX_D2D_BASE_SEQ_SVH

class pe_sbtx_D2D_base_seq extends uvm_sequence#(pe_sbtx_D2D_sequence_item);
  `uvm_object_utils(pe_sbtx_D2D_base_seq)
  `uvm_declare_p_sequencer(pe_sbtx_D2D_sequencer)
  
  function new(string name = "pe_sbtx_D2D_base_seq");
    super.new(name);
  endfunction
  
  // Helper task to drive a single D2D cycle and notify the D2D monitor
  virtual task drive_d2d_item(logic en = 1'b0, logic data_marker = 1'b0, logic comp_marker = 1'b0, logic[DATA_WIDTH-1 : 0] data = '0, bit rand_data = 1'b0);
    pe_sbtx_D2D_sequence_item req;
    logic                  _en          = en;
    logic                  _data_marker = data_marker;
    logic                  _comp_marker = comp_marker;
    logic [DATA_WIDTH-1:0] _data        = data;

    `uvm_do_with(req, {
      req.en          == _en;
      req.data_marker == _data_marker;
      req.comp_marker == _comp_marker;
      if (!rand_data) {
        req.data == _data;
      }
    })
    p_sequencer.seqr_aport.write(req);
  endtask
  
  // Helper task to drive N idle cycles on the D2D interface
  virtual task drive_d2d_idle(int cycles = 1);
    repeat (cycles) begin
      drive_d2d_item(1'b0, 1'b0, 1'b0, '0, 1'b0);
    end
  endtask
  
  virtual task body();
    drive_d2d_idle(1);
  endtask
endclass

`endif // PE_SBTX_D2D_BASE_SEQ_SVH