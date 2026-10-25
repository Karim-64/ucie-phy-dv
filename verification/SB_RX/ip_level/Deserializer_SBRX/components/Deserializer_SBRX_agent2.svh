`ifndef DESERIALIZER_SBRX_AGENT2_SVH
`define DESERIALIZER_SBRX_AGENT2_SVH

class Deserializer_SBRX_agent2 extends uvm_agent;
  `uvm_component_utils(Deserializer_SBRX_agent2)

  Deserializer_SBRX_sequencer2 seqr;
  Deserializer_SBRX_driver2 drv;
  Deserializer_SBRX_monitor2 mon;

  Deserializer_SBRX_agt_cfg_obj cfg;
  Deserializer_SBRX_drv_mon_cfg_obj drv_mon_cfg;
  uvm_analysis_port#(Deserializer_SBRX_sequence_item) agt_aport;

  function new(string name = "Deserializer_SBRX_agent2", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(Deserializer_SBRX_agt_cfg_obj)::get(this, "", "cfg2", cfg))
      `uvm_fatal("DESERIALIZER_SBRX_AGENT2", "Deserializer_SBRX_cfg_obj not found in config_db for Deserializer_SBRX_agent2")

    drv_mon_cfg = Deserializer_SBRX_drv_mon_cfg_obj::type_id::create("drv_mon_cfg");
    drv_mon_cfg.Deserializer_SBRX_vif = cfg.Deserializer_SBRX_vif;

    uvm_config_db#(Deserializer_SBRX_drv_mon_cfg_obj)::set(this, "*", "cfg", drv_mon_cfg);

    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = Deserializer_SBRX_sequencer2::type_id::create("seqr", this);
      drv = Deserializer_SBRX_driver2::type_id::create("drv", this);
    end

    mon = Deserializer_SBRX_monitor2::type_id::create("mon", this);
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

`endif // DESERIALIZER_SBRX_AGENT2_SVH
