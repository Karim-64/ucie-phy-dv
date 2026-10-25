`ifndef SYNCHRONIZER_SBRX_AGT_CFG_OBJ_SVH
`define SYNCHRONIZER_SBRX_AGT_CFG_OBJ_SVH

class Synchronizer_SBRX_agt_cfg_obj extends uvm_object;
  `uvm_object_utils(Synchronizer_SBRX_agt_cfg_obj);

  virtual Synchronizer_SBRX_if#() Synchronizer_SBRX_vif;
  uvm_active_passive_enum is_active;
  bit Synchronizer_SBRX_has_monitor;

  function new(string name = "Synchronizer_SBRX_agt_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // SYNCHRONIZER_SBRX_AGT_CFG_OBJ_SVH
