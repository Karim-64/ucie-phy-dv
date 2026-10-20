`ifndef DEMUX_AGENT_SVH
`define DEMUX_AGENT_SVH

class DEMUX_agent extends uvm_agent;
  `uvm_component_utils(DEMUX_agent)

  DEMUX_sequencer seqr;
  DEMUX_driver drv;
  DEMUX_monitor mon;

  DEMUX_agt_cfg_obj cfg;
  DEMUX_drv_mon_cfg_obj drv_mon_cfg;
  uvm_analysis_port#(DEMUX_sequence_item) agt_aport;

  function new(string name = "DEMUX_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(DEMUX_agt_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("DEMUX_AGENT", "DEMUX_cfg_obj not found in config_db for DEMUX_agent")

    drv_mon_cfg = DEMUX_drv_mon_cfg_obj::type_id::create("drv_mon_cfg");
    drv_mon_cfg.DEMUX_vif = cfg.DEMUX_vif;

    uvm_config_db#(DEMUX_drv_mon_cfg_obj)::set(this, "*", "cfg", drv_mon_cfg);

    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = DEMUX_sequencer::type_id::create("seqr", this);
      drv = DEMUX_driver::type_id::create("drv", this);
    end

    mon = DEMUX_monitor::type_id::create("mon", this);
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

`endif // DEMUX_AGENT_SVH
