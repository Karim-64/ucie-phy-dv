`ifndef SYNCHRONIZER_DRV_MON_CFG_OBJ_SVH
`define SYNCHRONIZER_DRV_MON_CFG_OBJ_SVH

class Synchronizer_drv_mon_cfg_obj extends uvm_object;
  `uvm_object_utils(Synchronizer_drv_mon_cfg_obj)

  virtual Synchronizer_if #() Synchronizer_vif;

  function new(string name = "Synchronizer_drv_mon_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // SYNCHRONIZER_DRV_MON_CFG_OBJ_SVH
