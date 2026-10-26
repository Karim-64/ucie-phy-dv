`ifndef SERIALIZER_SBTX_DRV_MON_CFG_OBJ_SVH
`define SERIALIZER_SBTX_DRV_MON_CFG_OBJ_SVH

class serializer_sbtx_drv_mon_cfg_obj extends uvm_object;
  `uvm_object_utils(serializer_sbtx_drv_mon_cfg_obj)

  virtual serializer_sbtx_if #(DATA_WIDTH) serializer_sbtx_vif;

  function new(string name = "serializer_sbtx_drv_mon_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // SERIALIZER_SBTX_DRV_MON_CFG_OBJ_SVH
