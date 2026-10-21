`ifndef UP_DOWN_COUNTER_AGT_CFG_OBJ_SVH
`define UP_DOWN_COUNTER_AGT_CFG_OBJ_SVH

class up_down_counter_agt_cfg_obj extends uvm_object;
  `uvm_object_utils(up_down_counter_agt_cfg_obj);

  virtual up_down_counter_if#(WIDTH) up_down_counter_vif;
  uvm_active_passive_enum is_active;
  bit up_down_counter_has_monitor;

  function new(string name = "up_down_counter_agt_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // UP_DOWN_COUNTER_AGT_CFG_OBJ_SVH
