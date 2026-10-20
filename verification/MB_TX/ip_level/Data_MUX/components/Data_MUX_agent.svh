`ifndef DATA_MUX_AGENT_SVH
`define DATA_MUX_AGENT_SVH

class Data_MUX_agent extends uvm_agent;
  `uvm_component_utils(Data_MUX_agent)

  Data_MUX_sequencer seqr;
  Data_MUX_driver drv;
  Data_MUX_monitor mon;

  Data_MUX_agt_cfg_obj cfg;
  Data_MUX_drv_mon_cfg_obj drv_mon_cfg;
  uvm_analysis_port#(Data_MUX_sequence_item) agt_aport;

  function new(string name = "Data_MUX_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(Data_MUX_agt_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("DATA_MUX_AGENT", "Data_MUX_cfg_obj not found in config_db for Data_MUX_agent")

    drv_mon_cfg = Data_MUX_drv_mon_cfg_obj::type_id::create("drv_mon_cfg");
    drv_mon_cfg.Data_MUX_vif = cfg.Data_MUX_vif;

    uvm_config_db#(Data_MUX_drv_mon_cfg_obj)::set(this, "*", "cfg", drv_mon_cfg);

    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = Data_MUX_sequencer::type_id::create("seqr", this);
      drv = Data_MUX_driver::type_id::create("drv", this);
    end

    mon = Data_MUX_monitor::type_id::create("mon", this);
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

`endif // DATA_MUX_AGENT_SVH
