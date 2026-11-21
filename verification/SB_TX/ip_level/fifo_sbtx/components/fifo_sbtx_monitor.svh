`ifndef FIFO_SBTX_MONITOR_SVH
`define FIFO_SBTX_MONITOR_SVH

class fifo_sbtx_monitor extends uvm_monitor;
  `uvm_component_utils(fifo_sbtx_monitor)

  fifo_sbtx_sequence_item seq_item;
  fifo_sbtx_sequence_item seqr_item;
  fifo_sbtx_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(fifo_sbtx_sequence_item, fifo_sbtx_monitor) mon_aimp;
  uvm_analysis_port#(fifo_sbtx_sequence_item) mon_aport;

  function new(string name = "fifo_sbtx_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(fifo_sbtx_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("FIFO_SBTX_MON", "fifo_sbtx_cfg_obj not found in config_db for fifo_sbtx_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(fifo_sbtx_sequence_item t);
    seqr_item = fifo_sbtx_sequence_item::type_id::create("seqr_item");
    seqr_item.rst_n = t.rst_n;
    seqr_item.wr_en = t.wr_en;
    seqr_item.rd_en = t.rd_en;
    seqr_item.UIE = t.UIE;
    seqr_item.data_in = t.data_in;
    seqr_item.Data_Marker = t.Data_Marker;
    seqr_item.Reg_Acc_Marker = t.Reg_Acc_Marker;
    seqr_item.Reg_Acc_Data_Marker = t.Reg_Acc_Data_Marker;
    seqr_item.Comp_Marker = t.Comp_Marker;
    seqr_item.Req_Resp_Marker = t.Req_Resp_Marker;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = fifo_sbtx_sequence_item::type_id::create("seq_item");
      @(cfg.fifo_sbtx_vif.mon_cb);
      if (seqr_item) begin
        seq_item.rst_n <= seqr_item.rst_n;
        seq_item.wr_en <= seqr_item.wr_en;
        seq_item.rd_en <= seqr_item.rd_en;
        seq_item.UIE <= seqr_item.UIE;
        seq_item.data_in <= seqr_item.data_in;
        seq_item.Data_Marker <= seqr_item.Data_Marker;
        seq_item.Reg_Acc_Marker <= seqr_item.Reg_Acc_Marker;
        seq_item.Reg_Acc_Data_Marker <= seqr_item.Reg_Acc_Data_Marker;
        seq_item.Comp_Marker <= seqr_item.Comp_Marker;
        seq_item.Req_Resp_Marker <= seqr_item.Req_Resp_Marker;
      end
      seq_item.data_out <= cfg.fifo_sbtx_vif.mon_cb.data_out;
      seq_item.Data_Marker_Out <= cfg.fifo_sbtx_vif.mon_cb.Data_Marker_Out;
      seq_item.Reg_Acc_Marker_Out <= cfg.fifo_sbtx_vif.mon_cb.Reg_Acc_Marker_Out;
      seq_item.Reg_Acc_Data_Marker_Out <= cfg.fifo_sbtx_vif.mon_cb.Reg_Acc_Data_Marker_Out;
      seq_item.Comp_Marker_Out <= cfg.fifo_sbtx_vif.mon_cb.Comp_Marker_Out;
      seq_item.empty <= cfg.fifo_sbtx_vif.mon_cb.empty;
      seq_item.rd_ack <= cfg.fifo_sbtx_vif.mon_cb.rd_ack;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // FIFO_SBTX_MONITOR_SVH
