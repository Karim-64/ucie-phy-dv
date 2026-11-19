`ifndef PE_SBTX_PHY_SANITY_SEQ_SVH
`define PE_SBTX_PHY_SANITY_SEQ_SVH

class pe_sbtx_PHY_sanity_seq extends pe_sbtx_PHY_base_seq;
  `uvm_object_utils(pe_sbtx_PHY_sanity_seq)
  
  function new(string name = "pe_sbtx_PHY_sanity_seq");
    super.new(name);
  endfunction
  
  task body();
    drive_phy_idle(1);
    
    drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b0), .rand_data(1'b0));
    drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b0), .rand_data(1'b1));
    drive_phy_idle(1);
    
    drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b1), .rand_data(1'b0));
    drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b1), .rand_data(1'b1));
    drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b1), .rand_data(1'b1));
    drive_phy_idle(1);
  endtask
endclass

`endif // PE_SBTX_PHY_SANITY_SEQ_SVH