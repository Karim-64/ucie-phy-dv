`ifndef TIMER_SBTX_ENV_CFG_OBJ_SVH
`define TIMER_SBTX_ENV_CFG_OBJ_SVH

class Timer_SBTX_env_cfg_obj extends uvm_object;
  `uvm_object_utils(Timer_SBTX_env_cfg_obj);

  virtual Timer_SBTX_if#(NO_OF_CYCLES) Timer_SBTX_vif;
  uvm_active_passive_enum active_passive_agents [string];
  bit Timer_SBTX_has_scoreboard;
  bit Timer_SBTX_has_subscriber;
  bit Timer_SBTX_has_agent;
  bit Timer_SBTX_has_monitor;

  function new(string name = "Timer_SBTX_env_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // TIMER_SBTX_ENV_CFG_OBJ_SVH
