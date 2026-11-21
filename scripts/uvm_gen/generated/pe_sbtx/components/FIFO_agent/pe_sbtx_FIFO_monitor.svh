`ifndef PE_SBTX_FIFO_MONITOR_SVH
`define PE_SBTX_FIFO_MONITOR_SVH

class pe_sbtx_FIFO_monitor extends uvm_monitor;
  `uvm_component_utils(pe_sbtx_FIFO_monitor)

  pe_sbtx_FIFO_sequence_item seq_item;
  pe_sbtx_FIFO_drv_mon_cfg_obj cfg;
  uvm_analysis_port#(pe_sbtx_FIFO_sequence_item) mon_aport;

  function new(string name = "pe_sbtx_FIFO_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(pe_sbtx_FIFO_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("PE_SBTX_FIFO_MON", "pe_sbtx_FIFO_drv_mon_cfg_obj not found in config_db for pe_sbtx_FIFO_monitor")
    mon_aport = new("mon_aport", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = pe_sbtx_FIFO_sequence_item::type_id::create("seq_item");
      @(cfg.pe_sbtx_vif.mon_cb);
      seq_item.fifo_wr <= cfg.pe_sbtx_vif.mon_cb.fifo_wr;
      seq_item.fifo_data <= cfg.pe_sbtx_vif.mon_cb.fifo_data;
      seq_item.data_marker <= cfg.pe_sbtx_vif.mon_cb.data_marker;
      seq_item.d2d_phy_marker <= cfg.pe_sbtx_vif.mon_cb.d2d_phy_marker;
      seq_item.comp_marker <= cfg.pe_sbtx_vif.mon_cb.comp_marker;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // PE_SBTX_FIFO_MONITOR_SVH
