`ifndef BIT_SYNC_SBTX_AGT_CFG_OBJ_SVH
`define BIT_SYNC_SBTX_AGT_CFG_OBJ_SVH

class BIT_SYNC_SBTX_agt_cfg_obj extends uvm_object;
  `uvm_object_utils(BIT_SYNC_SBTX_agt_cfg_obj);

  virtual BIT_SYNC_SBTX_if#(NUM_STAGES, BUS_WIDTH) BIT_SYNC_SBTX_vif;
  uvm_active_passive_enum is_active;
  bit BIT_SYNC_SBTX_has_monitor;

  function new(string name = "BIT_SYNC_SBTX_agt_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // BIT_SYNC_SBTX_AGT_CFG_OBJ_SVH
