`ifndef SYNCHRONIZER_ENV_CFG_OBJ_SVH
`define SYNCHRONIZER_ENV_CFG_OBJ_SVH

class Synchronizer_env_cfg_obj extends uvm_object;
  `uvm_object_utils(Synchronizer_env_cfg_obj);

  virtual Synchronizer_if#() Synchronizer_vif;
  uvm_active_passive_enum active_passive_agents [string];
  bit Synchronizer_has_scoreboard;
  bit Synchronizer_has_subscriber;
  bit Synchronizer_has_agent;
  bit Synchronizer_has_monitor;

  function new(string name = "Synchronizer_env_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // SYNCHRONIZER_ENV_CFG_OBJ_SVH
