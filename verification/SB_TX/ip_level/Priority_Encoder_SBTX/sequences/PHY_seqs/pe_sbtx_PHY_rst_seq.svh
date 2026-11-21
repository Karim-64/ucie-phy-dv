`ifndef PE_SBTX_PHY_rst_SEQ_SVH
`define PE_SBTX_PHY_rst_SEQ_SVH

class pe_sbtx_PHY_rst_seq extends pe_sbtx_PHY_base_seq;
  `uvm_object_utils(pe_sbtx_PHY_rst_seq)
  
  function new(string name = "pe_sbtx_PHY_rst_seq");
    super.new(name);
  endfunction
  
  task body();
    drive_phy_item(.rst_n(1'b0));
    drive_phy_item(.rst_n(1'b1));
  endtask
endclass

`endif // PE_SBTX_PHY_rst_SEQ_SVH