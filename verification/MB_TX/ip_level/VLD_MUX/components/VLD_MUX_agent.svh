`ifndef VLD_MUX_AGENT_SVH
`define VLD_MUX_AGENT_SVH

class VLD_MUX_agent extends uvm_agent;
  `uvm_component_utils(VLD_MUX_agent)

  VLD_MUX_sequencer seqr;
  VLD_MUX_driver drv;
  VLD_MUX_monitor mon;

  VLD_MUX_agt_cfg_obj cfg;
  VLD_MUX_drv_mon_cfg_obj drv_mon_cfg;
  uvm_analysis_port#(VLD_MUX_sequence_item) agt_aport;

  function new(string name = "VLD_MUX_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(VLD_MUX_agt_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("VLD_MUX_AGENT", "VLD_MUX_cfg_obj not found in config_db for VLD_MUX_agent")

    drv_mon_cfg = VLD_MUX_drv_mon_cfg_obj::type_id::create("drv_mon_cfg");
    drv_mon_cfg.VLD_MUX_vif = cfg.VLD_MUX_vif;

    uvm_config_db#(VLD_MUX_drv_mon_cfg_obj)::set(this, "*", "cfg", drv_mon_cfg);

    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = VLD_MUX_sequencer::type_id::create("seqr", this);
      drv = VLD_MUX_driver::type_id::create("drv", this);
    end

    mon = VLD_MUX_monitor::type_id::create("mon", this);
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

`endif // VLD_MUX_AGENT_SVH
