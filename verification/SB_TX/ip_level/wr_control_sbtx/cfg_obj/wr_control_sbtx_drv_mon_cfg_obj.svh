`ifndef WR_CONTROL_SBTX_DRV_MON_CFG_OBJ_SVH
`define WR_CONTROL_SBTX_DRV_MON_CFG_OBJ_SVH

class wr_control_sbtx_drv_mon_cfg_obj extends uvm_object;
  `uvm_object_utils(wr_control_sbtx_drv_mon_cfg_obj)

  virtual wr_control_sbtx_if #(NC) wr_control_sbtx_vif;

  function new(string name = "wr_control_sbtx_drv_mon_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // WR_CONTROL_SBTX_DRV_MON_CFG_OBJ_SVH
