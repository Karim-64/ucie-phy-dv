`ifndef PE_SBTX_FIFO_AGT_CFG_OBJ_SVH
`define PE_SBTX_FIFO_AGT_CFG_OBJ_SVH

class pe_sbtx_FIFO_agt_cfg_obj extends uvm_object;
  `uvm_object_utils(pe_sbtx_FIFO_agt_cfg_obj);

  virtual pe_sbtx_out_if#(DATA_WIDTH) pe_sbtx_vif;
  uvm_active_passive_enum is_active = UVM_PASSIVE;
  bit pe_sbtx_FIFO_has_monitor;

  function new(string name = "pe_sbtx_FIFO_agt_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // PE_SBTX_FIFO_AGT_CFG_OBJ_SVH
