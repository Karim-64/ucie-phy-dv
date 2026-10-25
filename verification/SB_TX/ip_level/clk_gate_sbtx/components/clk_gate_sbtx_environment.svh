`ifndef CLK_GATE_SBTX_ENVIRONMENT_SVH
`define CLK_GATE_SBTX_ENVIRONMENT_SVH

class clk_gate_sbtx_environment extends uvm_env;
  `uvm_component_utils(clk_gate_sbtx_environment)

  clk_gate_sbtx_agent agt;
  clk_gate_sbtx_scoreboard sb;
  clk_gate_sbtx_subscriber sub;

  clk_gate_sbtx_env_cfg_obj cfg;
  clk_gate_sbtx_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(clk_gate_sbtx_sequence_item) clk_gate_sbtx_env_aport;

  function new(string name = "clk_gate_sbtx_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    clk_gate_sbtx_env_aport = new("clk_gate_sbtx_env_aport", this);

    if (!uvm_config_db#(clk_gate_sbtx_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("CLK_GATE_SBTX_ENV", "clk_gate_sbtx_env_cfg_obj not found in config_db for clk_gate_sbtx_environment")

    if (cfg.clk_gate_sbtx_has_agent) begin
      agt_cfg = clk_gate_sbtx_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.clk_gate_sbtx_vif = cfg.clk_gate_sbtx_vif;
      agt_cfg.is_active = cfg.active_passive_agents["clk_gate_sbtx"];

      uvm_config_db#(clk_gate_sbtx_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.clk_gate_sbtx_has_agent)
      agt = clk_gate_sbtx_agent::type_id::create("agt", this);

    if (cfg.clk_gate_sbtx_has_scoreboard)
      sb = clk_gate_sbtx_scoreboard::type_id::create("sb", this);

    if (cfg.clk_gate_sbtx_has_subscriber)
      sub = clk_gate_sbtx_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.clk_gate_sbtx_has_agent) begin
      if (cfg.clk_gate_sbtx_has_scoreboard)
        agt.agt_aport.connect(sb.sb_aimp);

      if (cfg.clk_gate_sbtx_has_subscriber)
        agt.agt_aport.connect(sub.analysis_export);

      agt.agt_aport.connect(clk_gate_sbtx_env_aport);
    end
  endfunction
endclass

`endif // CLK_GATE_SBTX_ENVIRONMENT_SVH
