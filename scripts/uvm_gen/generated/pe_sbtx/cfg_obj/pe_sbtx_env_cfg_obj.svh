`ifndef PE_SBTX_ENV_CFG_OBJ_SVH
`define PE_SBTX_ENV_CFG_OBJ_SVH

class pe_sbtx_env_cfg_obj extends uvm_object;
  `uvm_object_utils(pe_sbtx_env_cfg_obj)

  // Virtual interfaces (one per agent)
  virtual pe_sbtx_in_if#(DATA_WIDTH) d2d_vif;
  virtual pe_sbtx_in_if#(DATA_WIDTH) phy_vif;
  virtual pe_sbtx_out_if#(DATA_WIDTH) fifo_vif;

  uvm_active_passive_enum active_passive_agents [string];
  bit pe_sbtx_has_scoreboard;
  bit pe_sbtx_has_coverage;
  bit pe_sbtx_has_D2D_agent;
  bit pe_sbtx_has_PHY_agent;
  bit pe_sbtx_has_FIFO_agent;

  function new(string name = "pe_sbtx_env_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // PE_SBTX_ENV_CFG_OBJ_SVH
