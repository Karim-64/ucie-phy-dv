`ifndef CREDITS_HANDLER_SBTX_DRV_MON_CFG_OBJ_SVH
`define CREDITS_HANDLER_SBTX_DRV_MON_CFG_OBJ_SVH

class Credits_Handler_SBTX_drv_mon_cfg_obj extends uvm_object;
  `uvm_object_utils(Credits_Handler_SBTX_drv_mon_cfg_obj)

  virtual Credits_Handler_SBTX_if #() Credits_Handler_SBTX_vif;

  function new(string name = "Credits_Handler_SBTX_drv_mon_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // CREDITS_HANDLER_SBTX_DRV_MON_CFG_OBJ_SVH
