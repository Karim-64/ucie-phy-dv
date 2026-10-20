`ifndef VLD_MUX_ENV_CFG_OBJ_SVH
`define VLD_MUX_ENV_CFG_OBJ_SVH

class VLD_MUX_env_cfg_obj extends uvm_object;
  `uvm_object_utils(VLD_MUX_env_cfg_obj);

  virtual VLD_MUX_if#() VLD_MUX_vif;
  uvm_active_passive_enum active_passive_agents [string];
  bit VLD_MUX_has_scoreboard;
  bit VLD_MUX_has_subscriber;
  bit VLD_MUX_has_agent;
  bit VLD_MUX_has_monitor;

  function new(string name = "VLD_MUX_env_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // VLD_MUX_ENV_CFG_OBJ_SVH
