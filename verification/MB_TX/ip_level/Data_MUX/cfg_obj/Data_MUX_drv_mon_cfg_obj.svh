`ifndef DATA_MUX_DRV_MON_CFG_OBJ_SVH
`define DATA_MUX_DRV_MON_CFG_OBJ_SVH

class Data_MUX_drv_mon_cfg_obj extends uvm_object;
  `uvm_object_utils(Data_MUX_drv_mon_cfg_obj)

  virtual Data_MUX_if #() Data_MUX_vif;

  function new(string name = "Data_MUX_drv_mon_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // DATA_MUX_DRV_MON_CFG_OBJ_SVH
