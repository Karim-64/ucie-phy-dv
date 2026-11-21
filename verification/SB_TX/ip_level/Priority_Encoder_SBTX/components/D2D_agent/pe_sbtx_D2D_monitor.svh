`ifndef PE_SBTX_D2D_MONITOR_SVH
`define PE_SBTX_D2D_MONITOR_SVH

class pe_sbtx_D2D_monitor extends uvm_monitor;
  `uvm_component_utils(pe_sbtx_D2D_monitor)

  pe_sbtx_D2D_sequence_item seq_item;
  pe_sbtx_D2D_sequence_item seqr_item;
  pe_sbtx_D2D_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(pe_sbtx_D2D_sequence_item, pe_sbtx_D2D_monitor) mon_aimp;
  uvm_analysis_port#(pe_sbtx_D2D_sequence_item) mon_aport;

  function new(string name = "pe_sbtx_D2D_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(pe_sbtx_D2D_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("PE_SBTX_D2D_MON", "pe_sbtx_D2D_drv_mon_cfg_obj not found in config_db for pe_sbtx_D2D_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(pe_sbtx_D2D_sequence_item t);
    seqr_item = pe_sbtx_D2D_sequence_item::type_id::create("seqr_item");
    seqr_item.en          = t.en;
    seqr_item.data_marker = t.data_marker;
    seqr_item.comp_marker = t.comp_marker;
    seqr_item.data        = t.data;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = pe_sbtx_D2D_sequence_item::type_id::create("seq_item");
      @(cfg.pe_sbtx_vif.mon_cb);
      if(seqr_item) begin
        seq_item.en          <= seqr_item.en;
        seq_item.data_marker <= seqr_item.data_marker;
        seq_item.comp_marker <= seqr_item.comp_marker;
        seq_item.data        <= seqr_item.data;
      end
      seq_item.resend_req  <= cfg.pe_sbtx_vif.mon_cb.resend_req;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // PE_SBTX_D2D_MONITOR_SVH
