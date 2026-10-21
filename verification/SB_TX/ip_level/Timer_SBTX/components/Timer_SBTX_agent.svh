`ifndef TIMER_SBTX_AGENT_SVH
`define TIMER_SBTX_AGENT_SVH

class Timer_SBTX_agent extends uvm_agent;
  `uvm_component_utils(Timer_SBTX_agent)

  Timer_SBTX_sequencer seqr;
  Timer_SBTX_driver drv;
  Timer_SBTX_monitor mon;

  Timer_SBTX_agt_cfg_obj cfg;
  Timer_SBTX_drv_mon_cfg_obj drv_mon_cfg;
  uvm_analysis_port#(Timer_SBTX_sequence_item) agt_aport;

  function new(string name = "Timer_SBTX_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(Timer_SBTX_agt_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("TIMER_SBTX_AGENT", "Timer_SBTX_cfg_obj not found in config_db for Timer_SBTX_agent")

    drv_mon_cfg = Timer_SBTX_drv_mon_cfg_obj::type_id::create("drv_mon_cfg");
    drv_mon_cfg.Timer_SBTX_vif = cfg.Timer_SBTX_vif;

    uvm_config_db#(Timer_SBTX_drv_mon_cfg_obj)::set(this, "*", "cfg", drv_mon_cfg);

    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = Timer_SBTX_sequencer::type_id::create("seqr", this);
      drv = Timer_SBTX_driver::type_id::create("drv", this);
    end

    mon = Timer_SBTX_monitor::type_id::create("mon", this);
    agt_aport = new("agt_aport", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (cfg.is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
      seqr.seqr_aport.connect(mon.mon_aimp);
    end
    mon.mon_aport.connect(agt_aport);
  endfunction
endclass

`endif // TIMER_SBTX_AGENT_SVH
