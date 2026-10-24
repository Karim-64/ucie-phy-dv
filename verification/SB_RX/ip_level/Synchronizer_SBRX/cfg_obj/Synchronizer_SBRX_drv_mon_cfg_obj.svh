`ifndef SYNCHRONIZER_SBRX_DRV_MON_CFG_OBJ_SVH
`define SYNCHRONIZER_SBRX_DRV_MON_CFG_OBJ_SVH

class Synchronizer_SBRX_drv_mon_cfg_obj extends uvm_object;
  `uvm_object_utils(Synchronizer_SBRX_drv_mon_cfg_obj)

  virtual Synchronizer_SBRX_if #() Synchronizer_SBRX_vif;

  function new(string name = "Synchronizer_SBRX_drv_mon_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // SYNCHRONIZER_SBRX_DRV_MON_CFG_OBJ_SVH
