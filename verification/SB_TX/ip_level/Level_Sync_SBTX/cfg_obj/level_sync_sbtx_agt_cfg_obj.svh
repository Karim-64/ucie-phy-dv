`ifndef LEVEL_SYNC_SBTX_AGT_CFG_OBJ_SVH
`define LEVEL_SYNC_SBTX_AGT_CFG_OBJ_SVH

class level_sync_sbtx_agt_cfg_obj extends uvm_object;
  `uvm_object_utils(level_sync_sbtx_agt_cfg_obj);

  virtual level_sync_sbtx_if#() level_sync_sbtx_vif;
  uvm_active_passive_enum is_active;
  
  function new(string name = "level_sync_sbtx_agt_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // LEVEL_SYNC_SBTX_AGT_CFG_OBJ_SVH
