`ifndef PAT_GEN_SBTX_ENVIRONMENT_SVH
`define PAT_GEN_SBTX_ENVIRONMENT_SVH

class pat_gen_sbtx_environment extends uvm_env;
  `uvm_component_utils(pat_gen_sbtx_environment)

  pat_gen_sbtx_agent agt;
  pat_gen_sbtx_scoreboard sb;
  pat_gen_sbtx_subscriber sub;

  pat_gen_sbtx_env_cfg_obj cfg;
  pat_gen_sbtx_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(pat_gen_sbtx_sequence_item) pat_gen_sbtx_env_aport;

  function new(string name = "pat_gen_sbtx_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    pat_gen_sbtx_env_aport = new("pat_gen_sbtx_env_aport", this);

    if (!uvm_config_db#(pat_gen_sbtx_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("PAT_GEN_SBTX_ENV", "pat_gen_sbtx_env_cfg_obj not found in config_db for pat_gen_sbtx_environment")

    if (cfg.pat_gen_sbtx_has_agent) begin
      agt_cfg = pat_gen_sbtx_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.pat_gen_sbtx_vif = cfg.pat_gen_sbtx_vif;
      agt_cfg.is_active = cfg.active_passive_agents["pat_gen_sbtx"];

      uvm_config_db#(pat_gen_sbtx_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.pat_gen_sbtx_has_agent)
      agt = pat_gen_sbtx_agent::type_id::create("agt", this);

    if (cfg.pat_gen_sbtx_has_scoreboard)
      sb = pat_gen_sbtx_scoreboard::type_id::create("sb", this);

    if (cfg.pat_gen_sbtx_has_subscriber)
      sub = pat_gen_sbtx_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.pat_gen_sbtx_has_agent) begin
      if (cfg.pat_gen_sbtx_has_scoreboard)
        agt.agt_aport.connect(sb.sb_aexp);

      if (cfg.pat_gen_sbtx_has_subscriber)
        agt.agt_aport.connect(sub.analysis_export);

      agt.agt_aport.connect(pat_gen_sbtx_env_aport);
    end
  endfunction
endclass

`endif // PAT_GEN_SBTX_ENVIRONMENT_SVH
