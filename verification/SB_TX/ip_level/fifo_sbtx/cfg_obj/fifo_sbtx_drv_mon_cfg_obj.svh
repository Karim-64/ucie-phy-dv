`ifndef FIFO_SBTX_DRV_MON_CFG_OBJ_SVH
`define FIFO_SBTX_DRV_MON_CFG_OBJ_SVH

class fifo_sbtx_drv_mon_cfg_obj extends uvm_object;
  `uvm_object_utils(fifo_sbtx_drv_mon_cfg_obj)

  virtual fifo_sbtx_if #(FIFO_WIDTH, FIFO_DEPTH) fifo_sbtx_vif;

  function new(string name = "fifo_sbtx_drv_mon_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // FIFO_SBTX_DRV_MON_CFG_OBJ_SVH
