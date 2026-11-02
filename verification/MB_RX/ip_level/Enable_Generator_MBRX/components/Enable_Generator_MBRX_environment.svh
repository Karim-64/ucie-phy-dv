`ifndef ENABLE_GENERATOR_MBRX_ENVIRONMENT_SVH
`define ENABLE_GENERATOR_MBRX_ENVIRONMENT_SVH

class Enable_Generator_MBRX_environment extends uvm_env;
  `uvm_component_utils(Enable_Generator_MBRX_environment)

  Enable_Generator_MBRX_agent agt;
  Enable_Generator_MBRX_scoreboard sb;
  Enable_Generator_MBRX_subscriber sub;

  Enable_Generator_MBRX_env_cfg_obj cfg;
  Enable_Generator_MBRX_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(Enable_Generator_MBRX_sequence_item) Enable_Generator_MBRX_env_aport;

  function new(string name = "Enable_Generator_MBRX_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    Enable_Generator_MBRX_env_aport = new("Enable_Generator_MBRX_env_aport", this);

    if (!uvm_config_db#(Enable_Generator_MBRX_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("ENABLE_GENERATOR_MBRX_ENV", "Enable_Generator_MBRX_env_cfg_obj not found in config_db for Enable_Generator_MBRX_environment")

    if (cfg.Enable_Generator_MBRX_has_agent) begin
      agt_cfg = Enable_Generator_MBRX_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.Enable_Generator_MBRX_vif = cfg.Enable_Generator_MBRX_vif;
      agt_cfg.is_active = cfg.active_passive_agents["Enable_Generator_MBRX"];

      uvm_config_db#(Enable_Generator_MBRX_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.Enable_Generator_MBRX_has_agent)
      agt = Enable_Generator_MBRX_agent::type_id::create("agt", this);

    if (cfg.Enable_Generator_MBRX_has_scoreboard)
      sb = Enable_Generator_MBRX_scoreboard::type_id::create("sb", this);

    if (cfg.Enable_Generator_MBRX_has_subscriber)
      sub = Enable_Generator_MBRX_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.Enable_Generator_MBRX_has_agent) begin
      if (cfg.Enable_Generator_MBRX_has_scoreboard)
        //agt.agt_aport.connect(sb.sb_aimp);
        agt.agt_aport.connect(sb.sb_export);


      if (cfg.Enable_Generator_MBRX_has_subscriber)
        agt.agt_aport.connect(sub.analysis_export);

      agt.agt_aport.connect(Enable_Generator_MBRX_env_aport);
    end
  endfunction
endclass

`endif // ENABLE_GENERATOR_MBRX_ENVIRONMENT_SVH
