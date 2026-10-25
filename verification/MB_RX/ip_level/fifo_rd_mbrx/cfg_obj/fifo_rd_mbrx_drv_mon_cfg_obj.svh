`ifndef FIFO_RD_MBRX_DRV_MON_CFG_OBJ_SVH
`define FIFO_RD_MBRX_DRV_MON_CFG_OBJ_SVH

class fifo_rd_mbrx_drv_mon_cfg_obj extends uvm_object;
  `uvm_object_utils(fifo_rd_mbrx_drv_mon_cfg_obj)

  virtual fifo_rd_mbrx_if #(P_SIZE) fifo_rd_mbrx_vif;

  function new(string name = "fifo_rd_mbrx_drv_mon_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // FIFO_RD_MBRX_DRV_MON_CFG_OBJ_SVH
