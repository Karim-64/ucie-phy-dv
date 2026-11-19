`ifndef CREDITS_HANDLER_SBTX_MONITOR_SVH
`define CREDITS_HANDLER_SBTX_MONITOR_SVH

class Credits_Handler_SBTX_monitor extends uvm_monitor;
  `uvm_component_utils(Credits_Handler_SBTX_monitor)

  Credits_Handler_SBTX_sequence_item seq_item;
  Credits_Handler_SBTX_sequence_item seqr_item;
  Credits_Handler_SBTX_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(Credits_Handler_SBTX_sequence_item, Credits_Handler_SBTX_monitor) mon_aimp;
  uvm_analysis_port#(Credits_Handler_SBTX_sequence_item) mon_aport;

  function new(string name = "Credits_Handler_SBTX_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(Credits_Handler_SBTX_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("CREDITS_HANDLER_SBTX_MON", "Credits_Handler_SBTX_cfg_obj not found in config_db for Credits_Handler_SBTX_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(Credits_Handler_SBTX_sequence_item t);
    seqr_item = Credits_Handler_SBTX_sequence_item::type_id::create("seqr_item");
    seqr_item.rst_n = t.rst_n;
    seqr_item.comp_sent = t.comp_sent;
    seqr_item.UIE = t.UIE;
    seqr_item.credit = t.credit;
    seqr_item.D2D_phy_marker = t.D2D_phy_marker;
    seqr_item.data_marker = t.data_marker;
    seqr_item.comp_marker = t.comp_marker;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = Credits_Handler_SBTX_sequence_item::type_id::create("seq_item");
      @(cfg.Credits_Handler_SBTX_vif.mon_cb);
      if (seqr_item) begin
        seq_item.rst_n <= seqr_item.rst_n;
        seq_item.comp_sent <= seqr_item.comp_sent;
        seq_item.UIE <= seqr_item.UIE;
        seq_item.credit <= seqr_item.credit;
        seq_item.D2D_phy_marker <= seqr_item.D2D_phy_marker;
        seq_item.data_marker <= seqr_item.data_marker;
        seq_item.comp_marker <= seqr_item.comp_marker;
      end
      seq_item.pl_cfg_crd <= cfg.Credits_Handler_SBTX_vif.mon_cb.pl_cfg_crd;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // CREDITS_HANDLER_SBTX_MONITOR_SVH
