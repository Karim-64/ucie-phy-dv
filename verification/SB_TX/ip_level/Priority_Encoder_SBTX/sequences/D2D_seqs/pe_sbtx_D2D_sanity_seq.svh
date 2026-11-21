`ifndef PE_SBTX_D2D_SANITY_SEQ_SVH
`define PE_SBTX_D2D_SANITY_SEQ_SVH

// =============================================================================
// Scenario 1 (D2D side): Normal Sanity Sequence
// - Cycles 1..3   : Initial reset & idle (3 cycles)
// - Cycles 4..6   : D2D 1-phase message (Data_Marker = 0) while PHY is idle (3 cycles)
// - Cycles 7..10  : D2D 2-phase message (Data_Marker = 1) + cooldown bubble (4 cycles)
// - Cycles 11..13 : Idle while PHY sends 1-phase message (3 cycles)
// - Cycles 14..17 : Idle while PHY sends 2-phase message (4 cycles)
// Total: 17 cycles
// =============================================================================
class pe_sbtx_D2D_sanity_seq extends pe_sbtx_D2D_base_seq;
  `uvm_object_utils(pe_sbtx_D2D_sanity_seq)
  
  function new(string name = "pe_sbtx_D2D_sanity_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    drive_d2d_idle(1);
    
    drive_d2d_item(.en(1'b1), .data_marker(1'b0), .comp_marker(1'b0), .rand_data(1'b0));
    drive_d2d_item(.en(1'b0), .data_marker(1'b0), .comp_marker(1'b0), .rand_data(1'b1));
    drive_d2d_idle(1);
    
    drive_d2d_item(.en(1'b1), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b0));
    drive_d2d_item(.en(1'b0), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b1));
    drive_d2d_item(.en(1'b0), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b1));
  endtask
endclass

`endif // PE_SBTX_D2D_SANITY_SEQ_SVH