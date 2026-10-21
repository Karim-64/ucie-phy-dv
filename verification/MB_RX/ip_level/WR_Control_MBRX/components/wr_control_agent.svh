`ifndef WR_CONTROL_AGENT_SVH
`define WR_CONTROL_AGENT_SVH

class wr_control_agent extends uvm_agent;
  `uvm_component_utils(wr_control_agent)

  wr_control_sequencer seqr;
  wr_control_driver drv;
  wr_control_monitor mon;

  wr_control_agt_cfg_obj cfg;
  wr_control_drv_mon_cfg_obj drv_mon_cfg;
  uvm_analysis_port#(wr_control_sequence_item) agt_aport;

  function new(string name = "wr_control_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(wr_control_agt_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("WR_CONTROL_AGENT", "wr_control_cfg_obj not found in config_db for wr_control_agent")

    drv_mon_cfg = wr_control_drv_mon_cfg_obj::type_id::create("drv_mon_cfg");
    drv_mon_cfg.wr_control_vif = cfg.wr_control_vif;

    uvm_config_db#(wr_control_drv_mon_cfg_obj)::set(this, "*", "cfg", drv_mon_cfg);

    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = wr_control_sequencer::type_id::create("seqr", this);
      drv = wr_control_driver::type_id::create("drv", this);
    end

    mon = wr_control_monitor::type_id::create("mon", this);
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

`endif // WR_CONTROL_AGENT_SVH
