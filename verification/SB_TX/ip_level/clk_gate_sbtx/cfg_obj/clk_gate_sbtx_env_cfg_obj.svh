`ifndef CLK_GATE_SBTX_ENV_CFG_OBJ_SVH
`define CLK_GATE_SBTX_ENV_CFG_OBJ_SVH

class clk_gate_sbtx_env_cfg_obj extends uvm_object;
  `uvm_object_utils(clk_gate_sbtx_env_cfg_obj);

  virtual clk_gate_sbtx_if#(PULSE_WIDTH) clk_gate_sbtx_vif;
  uvm_active_passive_enum active_passive_agents [string];
  bit clk_gate_sbtx_has_scoreboard;
  bit clk_gate_sbtx_has_subscriber;
  bit clk_gate_sbtx_has_agent;
  bit clk_gate_sbtx_has_monitor;

  function new(string name = "clk_gate_sbtx_env_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // CLK_GATE_SBTX_ENV_CFG_OBJ_SVH
