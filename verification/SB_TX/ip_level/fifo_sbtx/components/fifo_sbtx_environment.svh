`ifndef FIFO_SBTX_ENVIRONMENT_SVH
`define FIFO_SBTX_ENVIRONMENT_SVH

class fifo_sbtx_environment extends uvm_env;
  `uvm_component_utils(fifo_sbtx_environment)

  fifo_sbtx_agent agt;
  fifo_sbtx_scoreboard sb;
  fifo_sbtx_subscriber sub;

  fifo_sbtx_env_cfg_obj cfg;
  fifo_sbtx_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(fifo_sbtx_sequence_item) fifo_sbtx_env_aport;

  function new(string name = "fifo_sbtx_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    fifo_sbtx_env_aport = new("fifo_sbtx_env_aport", this);

    if (!uvm_config_db#(fifo_sbtx_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("FIFO_SBTX_ENV", "fifo_sbtx_env_cfg_obj not found in config_db for fifo_sbtx_environment")

    if (cfg.fifo_sbtx_has_agent) begin
      agt_cfg = fifo_sbtx_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.fifo_sbtx_vif = cfg.fifo_sbtx_vif;
      agt_cfg.is_active = cfg.active_passive_agents["fifo_sbtx"];

      uvm_config_db#(fifo_sbtx_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.fifo_sbtx_has_agent)
      agt = fifo_sbtx_agent::type_id::create("agt", this);

    if (cfg.fifo_sbtx_has_scoreboard)
      sb = fifo_sbtx_scoreboard::type_id::create("sb", this);

    if (cfg.fifo_sbtx_has_subscriber)
      sub = fifo_sbtx_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.fifo_sbtx_has_agent) begin
      if (cfg.fifo_sbtx_has_scoreboard)
        agt.agt_aport.connect(sb.ap.analysis_export);

      if (cfg.fifo_sbtx_has_subscriber)
        agt.agt_aport.connect(sub.ap.analysis_export);

      agt.agt_aport.connect(fifo_sbtx_env_aport);
    end
  endfunction
endclass

`endif // FIFO_SBTX_ENVIRONMENT_SVH
