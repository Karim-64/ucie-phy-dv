`ifndef LFSR_PER_LANE_ENV_CFG_OBJ_SVH
`define LFSR_PER_LANE_ENV_CFG_OBJ_SVH

class lfsr_per_lane_env_cfg_obj extends uvm_object;
  `uvm_object_utils(lfsr_per_lane_env_cfg_obj);

  virtual lfsr_per_lane_if#(WIDTH, Seed) lfsr_per_lane_vif;
  uvm_active_passive_enum active_passive_agents [string];
  bit lfsr_per_lane_has_scoreboard;
  bit lfsr_per_lane_has_subscriber;
  bit lfsr_per_lane_has_agent;
  bit lfsr_per_lane_has_monitor;

  function new(string name = "lfsr_per_lane_env_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // LFSR_PER_LANE_ENV_CFG_OBJ_SVH
