`ifndef DEMUX1X2_AGENT_SVH
`define DEMUX1X2_AGENT_SVH

class Demux1x2_agent extends uvm_agent;
  `uvm_component_utils(Demux1x2_agent)

  Demux1x2_sequencer seqr;
  Demux1x2_driver drv;
  Demux1x2_monitor mon;

  Demux1x2_agt_cfg_obj cfg;
  Demux1x2_drv_mon_cfg_obj drv_mon_cfg;
  uvm_analysis_port#(Demux1x2_sequence_item) agt_aport;

  function new(string name = "Demux1x2_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(Demux1x2_agt_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("DEMUX1X2_AGENT", "Demux1x2_cfg_obj not found in config_db for Demux1x2_agent")

    drv_mon_cfg = Demux1x2_drv_mon_cfg_obj::type_id::create("drv_mon_cfg");
    drv_mon_cfg.Demux1x2_vif = cfg.Demux1x2_vif;

    uvm_config_db#(Demux1x2_drv_mon_cfg_obj)::set(this, "*", "cfg", drv_mon_cfg);

    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = Demux1x2_sequencer::type_id::create("seqr", this);
      drv = Demux1x2_driver::type_id::create("drv", this);
    end

    mon = Demux1x2_monitor::type_id::create("mon", this);
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

`endif // DEMUX1X2_AGENT_SVH
