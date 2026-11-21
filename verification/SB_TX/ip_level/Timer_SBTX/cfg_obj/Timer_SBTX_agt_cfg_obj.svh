`ifndef TIMER_SBTX_AGT_CFG_OBJ_SVH
`define TIMER_SBTX_AGT_CFG_OBJ_SVH

class Timer_SBTX_agt_cfg_obj extends uvm_object;
  `uvm_object_utils(Timer_SBTX_agt_cfg_obj);

  virtual Timer_SBTX_if#(NO_OF_CYCLES) Timer_SBTX_vif;
  uvm_active_passive_enum is_active;
  bit Timer_SBTX_has_monitor;

  function new(string name = "Timer_SBTX_agt_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // TIMER_SBTX_AGT_CFG_OBJ_SVH
