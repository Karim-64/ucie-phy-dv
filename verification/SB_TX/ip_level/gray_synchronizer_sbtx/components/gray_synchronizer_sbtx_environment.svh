`ifndef GRAY_SYNCHRONIZER_SBTX_ENVIRONMENT_SVH
`define GRAY_SYNCHRONIZER_SBTX_ENVIRONMENT_SVH

class gray_synchronizer_sbtx_environment extends uvm_env;
  `uvm_component_utils(gray_synchronizer_sbtx_environment)

  gray_synchronizer_sbtx_agent agt;
  gray_synchronizer_sbtx_scoreboard sb;
  gray_synchronizer_sbtx_subscriber sub;

  gray_synchronizer_sbtx_env_cfg_obj cfg;
  gray_synchronizer_sbtx_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(gray_synchronizer_sbtx_sequence_item) gray_synchronizer_sbtx_env_aport;

  function new(string name = "gray_synchronizer_sbtx_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    gray_synchronizer_sbtx_env_aport = new("gray_synchronizer_sbtx_env_aport", this);

    if (!uvm_config_db#(gray_synchronizer_sbtx_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("GRAY_SYNCHRONIZER_SBTX_ENV", "gray_synchronizer_sbtx_env_cfg_obj not found in config_db for gray_synchronizer_sbtx_environment")

    if (cfg.gray_synchronizer_sbtx_has_agent) begin
      agt_cfg = gray_synchronizer_sbtx_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.gray_synchronizer_sbtx_vif = cfg.gray_synchronizer_sbtx_vif;
      agt_cfg.is_active = cfg.active_passive_agents["gray_synchronizer_sbtx"];

      uvm_config_db#(gray_synchronizer_sbtx_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.gray_synchronizer_sbtx_has_agent)
      agt = gray_synchronizer_sbtx_agent::type_id::create("agt", this);

    if (cfg.gray_synchronizer_sbtx_has_scoreboard)
      sb = gray_synchronizer_sbtx_scoreboard::type_id::create("sb", this);

    if (cfg.gray_synchronizer_sbtx_has_subscriber)
      sub = gray_synchronizer_sbtx_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.gray_synchronizer_sbtx_has_agent) begin
      if (cfg.gray_synchronizer_sbtx_has_scoreboard)
        agt.agt_aport.connect(sb.sb_aimp);

      if (cfg.gray_synchronizer_sbtx_has_subscriber)
        agt.agt_aport.connect(sub.analysis_export);

      agt.agt_aport.connect(gray_synchronizer_sbtx_env_aport);
    end
  endfunction
endclass

`endif // GRAY_SYNCHRONIZER_SBTX_ENVIRONMENT_SVH
