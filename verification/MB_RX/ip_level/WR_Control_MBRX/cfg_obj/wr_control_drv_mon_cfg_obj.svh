`ifndef WR_CONTROL_DRV_MON_CFG_OBJ_SVH
`define WR_CONTROL_DRV_MON_CFG_OBJ_SVH

class wr_control_drv_mon_cfg_obj extends uvm_object;
  `uvm_object_utils(wr_control_drv_mon_cfg_obj)

  virtual wr_control_if #(W_D_SIZE, WIDTH_DEGRADE_LENGTH) wr_control_vif;

  function new(string name = "wr_control_drv_mon_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // WR_CONTROL_DRV_MON_CFG_OBJ_SVH
