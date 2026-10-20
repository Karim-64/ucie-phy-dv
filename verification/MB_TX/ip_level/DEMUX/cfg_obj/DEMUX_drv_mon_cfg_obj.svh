`ifndef DEMUX_DRV_MON_CFG_OBJ_SVH
`define DEMUX_DRV_MON_CFG_OBJ_SVH

class DEMUX_drv_mon_cfg_obj extends uvm_object;
  `uvm_object_utils(DEMUX_drv_mon_cfg_obj)

  virtual DEMUX_if #() DEMUX_vif;

  function new(string name = "DEMUX_drv_mon_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // DEMUX_DRV_MON_CFG_OBJ_SVH
