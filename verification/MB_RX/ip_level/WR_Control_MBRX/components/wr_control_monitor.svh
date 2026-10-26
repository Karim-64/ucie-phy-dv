`ifndef WR_CONTROL_MONITOR_SVH
`define WR_CONTROL_MONITOR_SVH

class wr_control_monitor extends uvm_monitor;
  `uvm_component_utils(wr_control_monitor)

  wr_control_sequence_item seq_item;
  wr_control_sequence_item seqr_item;
  wr_control_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(wr_control_sequence_item, wr_control_monitor) mon_aimp;
  uvm_analysis_port#(wr_control_sequence_item) mon_aport;

  function new(string name = "wr_control_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(wr_control_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("WR_CONTROL_MON", "wr_control_cfg_obj not found in config_db for wr_control_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(wr_control_sequence_item t);
    seqr_item = wr_control_sequence_item::type_id::create("seqr_item");
    seqr_item.R_RST_n = t.R_RST_n;
    seqr_item.Ip_Bytes = t.Ip_Bytes;
    seqr_item.EN = t.EN;
    seqr_item.Deser_Done = t.Deser_Done;
    seqr_item.Width_Degrade = t.Width_Degrade;
    seqr_item.Width_Degrade_Update = t.Width_Degrade_Update;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = wr_control_sequence_item::type_id::create("seq_item");
      @(cfg.wr_control_vif.mon_cb);
      if (seqr_item) begin
        seq_item.R_RST_n <= seqr_item.R_RST_n;
        seq_item.Ip_Bytes <= seqr_item.Ip_Bytes;
        seq_item.EN <= seqr_item.EN;
        seq_item.Deser_Done <= seqr_item.Deser_Done;
        seq_item.Width_Degrade <= seqr_item.Width_Degrade;
        seq_item.Width_Degrade_Update <= seqr_item.Width_Degrade_Update;
      end
      seq_item.WR_EN <= cfg.wr_control_vif.mon_cb.WR_EN;
      seq_item.WR_DATA <= cfg.wr_control_vif.mon_cb.WR_DATA;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // WR_CONTROL_MONITOR_SVH
