`ifndef DATA_MUX_ENV_CFG_OBJ_SVH
`define DATA_MUX_ENV_CFG_OBJ_SVH

class Data_MUX_env_cfg_obj extends uvm_object;
  `uvm_object_utils(Data_MUX_env_cfg_obj);

  virtual Data_MUX_if#() Data_MUX_vif;
  uvm_active_passive_enum active_passive_agents [string];
  bit Data_MUX_has_scoreboard;
  bit Data_MUX_has_subscriber;
  bit Data_MUX_has_agent;
  bit Data_MUX_has_monitor;

  function new(string name = "Data_MUX_env_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // DATA_MUX_ENV_CFG_OBJ_SVH
