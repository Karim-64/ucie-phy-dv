`ifndef DEMUX_ENV_CFG_OBJ_SVH
`define DEMUX_ENV_CFG_OBJ_SVH

class demux_env_cfg_obj extends uvm_object;
  `uvm_object_utils(demux_env_cfg_obj);

  virtual demux_if#() demux_vif;
  uvm_active_passive_enum active_passive_agents [string];
  bit demux_has_scoreboard;
  bit demux_has_subscriber;
  bit demux_has_agent;
  bit demux_has_monitor;

  function new(string name = "demux_env_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // DEMUX_ENV_CFG_OBJ_SVH
