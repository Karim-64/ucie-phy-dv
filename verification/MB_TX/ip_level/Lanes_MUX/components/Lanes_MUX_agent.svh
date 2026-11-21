`ifndef LANES_MUX_AGENT_SVH
`define LANES_MUX_AGENT_SVH

class Lanes_MUX_agent extends uvm_agent;
  `uvm_component_utils(Lanes_MUX_agent)

  Lanes_MUX_sequencer seqr;
  Lanes_MUX_driver drv;
  Lanes_MUX_monitor mon;

  Lanes_MUX_agt_cfg_obj cfg;
  Lanes_MUX_drv_mon_cfg_obj drv_mon_cfg;
  uvm_analysis_port#(Lanes_MUX_sequence_item) agt_aport;

  function new(string name = "Lanes_MUX_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(Lanes_MUX_agt_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("LANES_MUX_AGENT", "Lanes_MUX_cfg_obj not found in config_db for Lanes_MUX_agent")

    drv_mon_cfg = Lanes_MUX_drv_mon_cfg_obj::type_id::create("drv_mon_cfg");
    drv_mon_cfg.Lanes_MUX_vif = cfg.Lanes_MUX_vif;

    uvm_config_db#(Lanes_MUX_drv_mon_cfg_obj)::set(this, "*", "cfg", drv_mon_cfg);

    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = Lanes_MUX_sequencer::type_id::create("seqr", this);
      drv = Lanes_MUX_driver::type_id::create("drv", this);
    end

    mon = Lanes_MUX_monitor::type_id::create("mon", this);
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

`endif // LANES_MUX_AGENT_SVH
