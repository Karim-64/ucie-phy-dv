`ifndef SYNC_FIFO_SBRX_ENVIRONMENT_SVH
`define SYNC_FIFO_SBRX_ENVIRONMENT_SVH

class Sync_fifo_SBRX_environment extends uvm_env;
  `uvm_component_utils(Sync_fifo_SBRX_environment)

  Sync_fifo_SBRX_agent agt;
  Sync_fifo_SBRX_scoreboard sb;
  Sync_fifo_SBRX_subscriber sub;

  Sync_fifo_SBRX_env_cfg_obj cfg;
  Sync_fifo_SBRX_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(Sync_fifo_SBRX_sequence_item) Sync_fifo_SBRX_env_aport;

  function new(string name = "Sync_fifo_SBRX_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    Sync_fifo_SBRX_env_aport = new("Sync_fifo_SBRX_env_aport", this);

    if (!uvm_config_db#(Sync_fifo_SBRX_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("SYNC_FIFO_SBRX_ENV", "Sync_fifo_SBRX_env_cfg_obj not found in config_db for Sync_fifo_SBRX_environment")

    if (cfg.Sync_fifo_SBRX_has_agent) begin
      agt_cfg = Sync_fifo_SBRX_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.Sync_fifo_SBRX_vif = cfg.Sync_fifo_SBRX_vif;
      agt_cfg.is_active = cfg.active_passive_agents["Sync_fifo_SBRX"];

      uvm_config_db#(Sync_fifo_SBRX_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.Sync_fifo_SBRX_has_agent)
      agt = Sync_fifo_SBRX_agent::type_id::create("agt", this);

    if (cfg.Sync_fifo_SBRX_has_scoreboard)
      sb = Sync_fifo_SBRX_scoreboard::type_id::create("sb", this);

    if (cfg.Sync_fifo_SBRX_has_subscriber)
      sub = Sync_fifo_SBRX_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.Sync_fifo_SBRX_has_agent) begin
      if (cfg.Sync_fifo_SBRX_has_scoreboard)
        agt.agt_aport.connect(sb.exp);

      if (cfg.Sync_fifo_SBRX_has_subscriber)
        agt.agt_aport.connect(sub.exp);

      agt.agt_aport.connect(Sync_fifo_SBRX_env_aport);
    end
  endfunction
endclass

`endif // SYNC_FIFO_SBRX_ENVIRONMENT_SVH
