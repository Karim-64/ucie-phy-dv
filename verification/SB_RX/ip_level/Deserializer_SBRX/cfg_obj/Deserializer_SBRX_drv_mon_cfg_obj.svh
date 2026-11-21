`ifndef DESERIALIZER_SBRX_DRV_MON_CFG_OBJ_SVH
`define DESERIALIZER_SBRX_DRV_MON_CFG_OBJ_SVH

class Deserializer_SBRX_drv_mon_cfg_obj extends uvm_object;
  `uvm_object_utils(Deserializer_SBRX_drv_mon_cfg_obj)

  virtual Deserializer_SBRX_if #(DATA_WIDTH) Deserializer_SBRX_vif;

  function new(string name = "Deserializer_SBRX_drv_mon_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // DESERIALIZER_SBRX_DRV_MON_CFG_OBJ_SVH
