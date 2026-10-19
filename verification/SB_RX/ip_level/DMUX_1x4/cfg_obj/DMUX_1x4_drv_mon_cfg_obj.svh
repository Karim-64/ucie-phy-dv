`ifndef DMUX_1X4_DRV_MON_CFG_OBJ_SVH
`define DMUX_1X4_DRV_MON_CFG_OBJ_SVH

class DMUX_1x4_drv_mon_cfg_obj extends uvm_object;
  `uvm_object_utils(DMUX_1x4_drv_mon_cfg_obj)

  virtual DMUX_1x4_if #(DATA_WIDTH, DESTINATION_SEL) DMUX_1x4_vif;

  function new(string name = "DMUX_1x4_drv_mon_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // DMUX_1X4_DRV_MON_CFG_OBJ_SVH
