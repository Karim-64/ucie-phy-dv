`ifndef DEMUX_ENV_CFG_OBJ_SVH
`define DEMUX_ENV_CFG_OBJ_SVH

class DEMUX_env_cfg_obj extends uvm_object;
  `uvm_object_utils(DEMUX_env_cfg_obj);

  virtual DEMUX_if#() DEMUX_vif;
  uvm_active_passive_enum active_passive_agents [string];
  bit DEMUX_has_scoreboard;
  bit DEMUX_has_subscriber;
  bit DEMUX_has_agent;
  bit DEMUX_has_monitor;

  function new(string name = "DEMUX_env_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // DEMUX_ENV_CFG_OBJ_SVH
