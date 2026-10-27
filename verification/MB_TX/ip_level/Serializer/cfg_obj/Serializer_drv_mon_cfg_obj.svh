`ifndef SERIALIZER_DRV_MON_CFG_OBJ_SVH
`define SERIALIZER_DRV_MON_CFG_OBJ_SVH

class Serializer_drv_mon_cfg_obj extends uvm_object;
  `uvm_object_utils(Serializer_drv_mon_cfg_obj)

  virtual Serializer_if #() Serializer_vif;

  function new(string name = "Serializer_drv_mon_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // SERIALIZER_DRV_MON_CFG_OBJ_SVH
