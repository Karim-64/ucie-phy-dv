`ifndef SYNCHRONIZER_AGT_CFG_OBJ_SVH
`define SYNCHRONIZER_AGT_CFG_OBJ_SVH

class Synchronizer_agt_cfg_obj extends uvm_object;
  `uvm_object_utils(Synchronizer_agt_cfg_obj);

  virtual Synchronizer_if#() Synchronizer_vif;
  uvm_active_passive_enum is_active;
  bit Synchronizer_has_monitor;

  function new(string name = "Synchronizer_agt_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // SYNCHRONIZER_AGT_CFG_OBJ_SVH
