`ifndef CREDITS_HANDLER_SBTX_ENV_CFG_OBJ_SVH
`define CREDITS_HANDLER_SBTX_ENV_CFG_OBJ_SVH

class Credits_Handler_SBTX_env_cfg_obj extends uvm_object;
  `uvm_object_utils(Credits_Handler_SBTX_env_cfg_obj);

  virtual Credits_Handler_SBTX_if#() Credits_Handler_SBTX_vif;
  uvm_active_passive_enum active_passive_agents [string];
  bit Credits_Handler_SBTX_has_scoreboard;
  bit Credits_Handler_SBTX_has_subscriber;
  bit Credits_Handler_SBTX_has_agent;
  bit Credits_Handler_SBTX_has_monitor;

  function new(string name = "Credits_Handler_SBTX_env_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // CREDITS_HANDLER_SBTX_ENV_CFG_OBJ_SVH
