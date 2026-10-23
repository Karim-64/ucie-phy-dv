`ifndef WR_CONTROL_SBTX_MONITOR_SVH
`define WR_CONTROL_SBTX_MONITOR_SVH

class wr_control_sbtx_monitor extends uvm_monitor;
  `uvm_component_utils(wr_control_sbtx_monitor)

  wr_control_sbtx_sequence_item seq_item;
  wr_control_sbtx_sequence_item seqr_item;
  wr_control_sbtx_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(wr_control_sbtx_sequence_item, wr_control_sbtx_monitor) mon_aimp;
  uvm_analysis_port#(wr_control_sbtx_sequence_item) mon_aport;

  function new(string name = "wr_control_sbtx_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(wr_control_sbtx_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("WR_CONTROL_SBTX_MON", "wr_control_sbtx_cfg_obj not found in config_db for wr_control_sbtx_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(wr_control_sbtx_sequence_item t);
    seqr_item = wr_control_sbtx_sequence_item#()::type_id::create("seqr_item");
    seqr_item.RST_n = t.RST_n;
    seqr_item.lp_cfg_vld = t.lp_cfg_vld;
    seqr_item.lp_cfg = t.lp_cfg;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = wr_control_sbtx_sequence_item#()::type_id::create("seq_item");
      @(cfg.wr_control_sbtx_vif.mon_cb);
      if (seqr_item) begin
        seq_item.RST_n <= seqr_item.RST_n;
        seq_item.lp_cfg_vld <= seqr_item.lp_cfg_vld;
        seq_item.lp_cfg <= seqr_item.lp_cfg;
      end
      seq_item.Interface_Message <= cfg.wr_control_sbtx_vif.mon_cb.Interface_Message;
      seq_item.Data_Marker <= cfg.wr_control_sbtx_vif.mon_cb.Data_Marker;
      seq_item.Reg_Acc_Marker <= cfg.wr_control_sbtx_vif.mon_cb.Reg_Acc_Marker;
      seq_item.Reg_Acc_Data_Marker <= cfg.wr_control_sbtx_vif.mon_cb.Reg_Acc_Data_Marker;
      seq_item.Comp_Marker <= cfg.wr_control_sbtx_vif.mon_cb.Comp_Marker;
      seq_item.Req_Resp_Marker <= cfg.wr_control_sbtx_vif.mon_cb.Req_Resp_Marker;
      seq_item.Error_Handler <= cfg.wr_control_sbtx_vif.mon_cb.Error_Handler;
      seq_item.FIFO_WR <= cfg.wr_control_sbtx_vif.mon_cb.FIFO_WR;
      seq_item.UIE <= cfg.wr_control_sbtx_vif.mon_cb.UIE;

      seq_item.Interface_Message_exp <= cfg.wr_control_sbtx_vif.mon_cb.Interface_Message_exp;
      seq_item.Data_Marker_exp <= cfg.wr_control_sbtx_vif.mon_cb.Data_Marker_exp;
      seq_item.Reg_Acc_Marker_exp <= cfg.wr_control_sbtx_vif.mon_cb.Reg_Acc_Marker_exp;
      seq_item.Reg_Acc_Data_Marker_exp <= cfg.wr_control_sbtx_vif.mon_cb.Reg_Acc_Data_Marker_exp;
      seq_item.Comp_Marker_exp <= cfg.wr_control_sbtx_vif.mon_cb.Comp_Marker_exp;
      seq_item.Req_Resp_Marker_exp <= cfg.wr_control_sbtx_vif.mon_cb.Req_Resp_Marker_exp;
      seq_item.Error_Handler_exp <= cfg.wr_control_sbtx_vif.mon_cb.Error_Handler_exp;
      seq_item.FIFO_WR_exp <= cfg.wr_control_sbtx_vif.mon_cb.FIFO_WR_exp;
      seq_item.UIE_exp <= cfg.wr_control_sbtx_vif.mon_cb.UIE_exp;

      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // WR_CONTROL_SBTX_MONITOR_SVH
