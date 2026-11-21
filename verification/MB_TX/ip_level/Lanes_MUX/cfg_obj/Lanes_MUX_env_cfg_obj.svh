`ifndef LANES_MUX_ENV_CFG_OBJ_SVH
`define LANES_MUX_ENV_CFG_OBJ_SVH

class Lanes_MUX_env_cfg_obj extends uvm_object;
  `uvm_object_utils(Lanes_MUX_env_cfg_obj);

  virtual Lanes_MUX_if#() Lanes_MUX_vif;
  uvm_active_passive_enum active_passive_agents [string];
  bit Lanes_MUX_has_scoreboard;
  bit Lanes_MUX_has_subscriber;
  bit Lanes_MUX_has_agent;
  bit Lanes_MUX_has_monitor;

  function new(string name = "Lanes_MUX_env_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // LANES_MUX_ENV_CFG_OBJ_SVH
