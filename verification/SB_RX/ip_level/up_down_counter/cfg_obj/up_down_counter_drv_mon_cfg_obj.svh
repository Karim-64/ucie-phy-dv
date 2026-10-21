`ifndef UP_DOWN_COUNTER_DRV_MON_CFG_OBJ_SVH
`define UP_DOWN_COUNTER_DRV_MON_CFG_OBJ_SVH

class up_down_counter_drv_mon_cfg_obj extends uvm_object;
  `uvm_object_utils(up_down_counter_drv_mon_cfg_obj)

  virtual up_down_counter_if #(WIDTH) up_down_counter_vif;

  function new(string name = "up_down_counter_drv_mon_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // UP_DOWN_COUNTER_DRV_MON_CFG_OBJ_SVH
