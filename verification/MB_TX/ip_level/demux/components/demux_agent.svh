`ifndef DEMUX_AGENT_SVH
`define DEMUX_AGENT_SVH

class demux_agent extends uvm_agent;
  `uvm_component_utils(demux_agent)

  demux_sequencer seqr;
  demux_driver drv;
  demux_monitor mon;

  demux_agt_cfg_obj cfg;
  demux_drv_mon_cfg_obj drv_mon_cfg;
  uvm_analysis_port#(demux_sequence_item) agt_aport;

  function new(string name = "demux_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(demux_agt_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("DEMUX_AGENT", "demux_cfg_obj not found in config_db for demux_agent")

    drv_mon_cfg = demux_drv_mon_cfg_obj::type_id::create("drv_mon_cfg");
    drv_mon_cfg.demux_vif = cfg.demux_vif;

    uvm_config_db#(demux_drv_mon_cfg_obj)::set(this, "*", "cfg", drv_mon_cfg);

    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = demux_sequencer::type_id::create("seqr", this);
      drv = demux_driver::type_id::create("drv", this);
    end

    mon = demux_monitor::type_id::create("mon", this);
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
