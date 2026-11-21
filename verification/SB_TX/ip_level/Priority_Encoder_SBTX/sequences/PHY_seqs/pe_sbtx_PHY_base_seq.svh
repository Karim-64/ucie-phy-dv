`ifndef PE_SBTX_PHY_BASE_SEQ_SVH
`define PE_SBTX_PHY_BASE_SEQ_SVH

class pe_sbtx_PHY_base_seq extends uvm_sequence#(pe_sbtx_PHY_sequence_item);
  `uvm_object_utils(pe_sbtx_PHY_base_seq)
  `uvm_declare_p_sequencer(pe_sbtx_PHY_sequencer)
  
  function new(string name = "pe_sbtx_PHY_base_seq");
    super.new(name);
  endfunction
  
  // Helper task to drive a single PHY cycle and notify the PHY monitor
  virtual task drive_phy_item(logic rst_n = 1'b1, logic en = 1'b0, logic data_marker = 1'b0, logic[DATA_WIDTH-1 : 0] data = '0, bit rand_data = 1'b0);
    pe_sbtx_PHY_sequence_item req;
    logic                  _rst_n       = rst_n;
    logic                  _en          = en;
    logic                  _data_marker = data_marker;
    logic [DATA_WIDTH-1:0] _data        = data;

    `uvm_do_with(req, {
      req.rst_n       == _rst_n;
      req.en          == _en;
      req.data_marker == _data_marker;
      req.comp_marker == 1'b0;
      if(!rand_data)  req.data == _data;
    })
    p_sequencer.seqr_aport.write(req);
  endtask
  
  // Helper task to drive N idle cycles (with rst_n = 1) on the PHY interface
  virtual task drive_phy_idle(int cycles = 1);
    repeat (cycles) begin
      drive_phy_item(1'b1, 1'b0, 1'b0, '0, 1'b0);
    end
  endtask
endclass

`endif // PE_SBTX_PHY_BASE_SEQ_SVH