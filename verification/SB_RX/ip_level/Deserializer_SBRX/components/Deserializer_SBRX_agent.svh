`ifndef DESERIALIZER_SBRX_AGENT_SVH
`define DESERIALIZER_SBRX_AGENT_SVH

class Deserializer_SBRX_agent extends uvm_agent;
  `uvm_component_utils(Deserializer_SBRX_agent)

  Deserializer_SBRX_sequencer seqr;
  Deserializer_SBRX_driver drv;
  Deserializer_SBRX_monitor mon;

  Deserializer_SBRX_agt_cfg_obj cfg;
  Deserializer_SBRX_drv_mon_cfg_obj drv_mon_cfg;
  uvm_analysis_port#(Deserializer_SBRX_sequence_item) agt_aport;

  function new(string name = "Deserializer_SBRX_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(Deserializer_SBRX_agt_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("DESERIALIZER_SBRX_AGENT", "Deserializer_SBRX_cfg_obj not found in config_db for Deserializer_SBRX_agent")

    drv_mon_cfg = Deserializer_SBRX_drv_mon_cfg_obj::type_id::create("drv_mon_cfg");
    drv_mon_cfg.Deserializer_SBRX_vif = cfg.Deserializer_SBRX_vif;

    uvm_config_db#(Deserializer_SBRX_drv_mon_cfg_obj)::set(this, "*", "cfg", drv_mon_cfg);

    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = Deserializer_SBRX_sequencer::type_id::create("seqr", this);
      drv = Deserializer_SBRX_driver::type_id::create("drv", this);
    end

    mon = Deserializer_SBRX_monitor::type_id::create("mon", this);
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

`endif // DESERIALIZER_SBRX_AGENT_SVH
