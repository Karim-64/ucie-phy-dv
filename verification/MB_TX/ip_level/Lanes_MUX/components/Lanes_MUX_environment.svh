`ifndef LANES_MUX_ENVIRONMENT_SVH
`define LANES_MUX_ENVIRONMENT_SVH

class Lanes_MUX_environment extends uvm_env;
  `uvm_component_utils(Lanes_MUX_environment)

  Lanes_MUX_agent agt;
  Lanes_MUX_scoreboard sb;
  Lanes_MUX_subscriber sub;

  Lanes_MUX_env_cfg_obj cfg;
  Lanes_MUX_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(Lanes_MUX_sequence_item) Lanes_MUX_env_aport;

  function new(string name = "Lanes_MUX_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    Lanes_MUX_env_aport = new("Lanes_MUX_env_aport", this);

    if (!uvm_config_db#(Lanes_MUX_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("LANES_MUX_ENV", "Lanes_MUX_env_cfg_obj not found in config_db for Lanes_MUX_environment")

    if (cfg.Lanes_MUX_has_agent) begin
      agt_cfg = Lanes_MUX_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.Lanes_MUX_vif = cfg.Lanes_MUX_vif;
      agt_cfg.is_active = cfg.active_passive_agents["Lanes_MUX"];

      uvm_config_db#(Lanes_MUX_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.Lanes_MUX_has_agent)
      agt = Lanes_MUX_agent::type_id::create("agt", this);

    if (cfg.Lanes_MUX_has_scoreboard)
      sb = Lanes_MUX_scoreboard::type_id::create("sb", this);

    if (cfg.Lanes_MUX_has_subscriber)
      sub = Lanes_MUX_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.Lanes_MUX_has_agent) begin
      if (cfg.Lanes_MUX_has_scoreboard)
        agt.agt_aport.connect(sb.sb_aimp);

      if (cfg.Lanes_MUX_has_subscriber)
        agt.agt_aport.connect(sub.analysis_export);

      agt.agt_aport.connect(Lanes_MUX_env_aport);
    end
  endfunction
endclass

`endif // LANES_MUX_ENVIRONMENT_SVH
