`ifndef MEM_ENV_CFG_OBJ_SVH
`define MEM_ENV_CFG_OBJ_SVH

class mem_env_cfg_obj extends uvm_object;
  `uvm_object_utils(mem_env_cfg_obj);

  virtual mem_if#(DATA_WIDTH, ADDRESS_WIDTH) mem_vif;
  uvm_active_passive_enum active_passive_agents [string];
  bit mem_has_scoreboard;
  bit mem_has_subscriber;
  bit mem_has_agent;
  bit mem_has_monitor;

  function new(string name = "mem_env_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // MEM_ENV_CFG_OBJ_SVH
