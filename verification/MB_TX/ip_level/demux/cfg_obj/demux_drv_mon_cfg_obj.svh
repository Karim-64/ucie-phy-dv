`ifndef DEMUX_DRV_MON_CFG_OBJ_SVH
`define DEMUX_DRV_MON_CFG_OBJ_SVH

class demux_drv_mon_cfg_obj extends uvm_object;
  `uvm_object_utils(demux_drv_mon_cfg_obj)

  virtual demux_if #() demux_vif;

  function new(string name = "demux_drv_mon_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // DEMUX_DRV_MON_CFG_OBJ_SVH
