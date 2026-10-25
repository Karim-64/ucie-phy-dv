`ifndef FIFO_RD_MBRX_ENVIRONMENT_SVH
`define FIFO_RD_MBRX_ENVIRONMENT_SVH

class fifo_rd_mbrx_environment extends uvm_env;
  `uvm_component_utils(fifo_rd_mbrx_environment)

  fifo_rd_mbrx_agent agt;
  fifo_rd_mbrx_scoreboard sb;
  fifo_rd_mbrx_subscriber sub;

  fifo_rd_mbrx_env_cfg_obj cfg;
  fifo_rd_mbrx_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(fifo_rd_mbrx_sequence_item) fifo_rd_mbrx_env_aport;

  function new(string name = "fifo_rd_mbrx_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    fifo_rd_mbrx_env_aport = new("fifo_rd_mbrx_env_aport", this);

    if (!uvm_config_db#(fifo_rd_mbrx_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("FIFO_RD_MBRX_ENV", "fifo_rd_mbrx_env_cfg_obj not found in config_db for fifo_rd_mbrx_environment")

    if (cfg.fifo_rd_mbrx_has_agent) begin
      agt_cfg = fifo_rd_mbrx_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.fifo_rd_mbrx_vif = cfg.fifo_rd_mbrx_vif;
      agt_cfg.is_active = cfg.active_passive_agents["fifo_rd_mbrx"];

      uvm_config_db#(fifo_rd_mbrx_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.fifo_rd_mbrx_has_agent)
      agt = fifo_rd_mbrx_agent::type_id::create("agt", this);

    if (cfg.fifo_rd_mbrx_has_scoreboard)
      sb = fifo_rd_mbrx_scoreboard::type_id::create("sb", this);

    if (cfg.fifo_rd_mbrx_has_subscriber)
      sub = fifo_rd_mbrx_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.fifo_rd_mbrx_has_agent) begin
      if (cfg.fifo_rd_mbrx_has_scoreboard)
        agt.agt_aport.connect(sb.sb_aimp);

      if (cfg.fifo_rd_mbrx_has_subscriber)
        agt.agt_aport.connect(sub.analysis_export);

      agt.agt_aport.connect(fifo_rd_mbrx_env_aport);
    end
  endfunction
endclass

`endif // FIFO_RD_MBRX_ENVIRONMENT_SVH
