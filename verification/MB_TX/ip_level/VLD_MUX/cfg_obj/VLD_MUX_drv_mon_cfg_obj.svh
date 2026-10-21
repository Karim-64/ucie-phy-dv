`ifndef VLD_MUX_DRV_MON_CFG_OBJ_SVH
`define VLD_MUX_DRV_MON_CFG_OBJ_SVH

class VLD_MUX_drv_mon_cfg_obj extends uvm_object;
  `uvm_object_utils(VLD_MUX_drv_mon_cfg_obj)

  virtual VLD_MUX_if #() VLD_MUX_vif;

  function new(string name = "VLD_MUX_drv_mon_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // VLD_MUX_DRV_MON_CFG_OBJ_SVH
