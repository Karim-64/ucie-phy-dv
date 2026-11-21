`ifndef GRAY_SYNCHRONIZER_SBTX_DRV_MON_CFG_OBJ_SVH
`define GRAY_SYNCHRONIZER_SBTX_DRV_MON_CFG_OBJ_SVH

class gray_synchronizer_sbtx_drv_mon_cfg_obj extends uvm_object;
  `uvm_object_utils(gray_synchronizer_sbtx_drv_mon_cfg_obj)

  virtual gray_synchronizer_sbtx_if #(DATA_SIZE) gray_synchronizer_sbtx_vif;

  function new(string name = "gray_synchronizer_sbtx_drv_mon_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // GRAY_SYNCHRONIZER_SBTX_DRV_MON_CFG_OBJ_SVH
