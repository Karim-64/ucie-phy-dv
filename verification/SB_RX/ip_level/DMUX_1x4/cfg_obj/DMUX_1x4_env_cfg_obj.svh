`ifndef DMUX_1X4_ENV_CFG_OBJ_SVH
`define DMUX_1X4_ENV_CFG_OBJ_SVH

class DMUX_1x4_env_cfg_obj extends uvm_object;
  `uvm_object_utils(DMUX_1x4_env_cfg_obj);

  virtual DMUX_1x4_if#(DATA_WIDTH, DESTINATION_SEL) DMUX_1x4_vif;
  uvm_active_passive_enum active_passive_agents [string];
  bit DMUX_1x4_has_scoreboard;
  bit DMUX_1x4_has_subscriber;
  bit DMUX_1x4_has_agent;
  bit DMUX_1x4_has_monitor;

  function new(string name = "DMUX_1x4_env_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // DMUX_1X4_ENV_CFG_OBJ_SVH
