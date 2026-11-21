`ifndef PE_SBTX_D2D_AGT_CFG_OBJ_SVH
`define PE_SBTX_D2D_AGT_CFG_OBJ_SVH

class pe_sbtx_D2D_agt_cfg_obj extends uvm_object;
  `uvm_object_utils(pe_sbtx_D2D_agt_cfg_obj)

  virtual pe_sbtx_in_if#(DATA_WIDTH) pe_sbtx_vif;
  uvm_active_passive_enum is_active;
  bit pe_sbtx_D2D_has_monitor;

  function new(string name = "pe_sbtx_D2D_agt_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // PE_SBTX_D2D_AGT_CFG_OBJ_SVH
