`ifndef CLK_GATE_SBTX_MONITOR_SVH
`define CLK_GATE_SBTX_MONITOR_SVH

class clk_gate_sbtx_monitor extends uvm_monitor;
  `uvm_component_utils(clk_gate_sbtx_monitor)

  clk_gate_sbtx_sequence_item seq_item;
  clk_gate_sbtx_sequence_item seqr_item;
  clk_gate_sbtx_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(clk_gate_sbtx_sequence_item, clk_gate_sbtx_monitor) mon_aimp;
  uvm_analysis_port#(clk_gate_sbtx_sequence_item) mon_aport;

  function new(string name = "clk_gate_sbtx_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(clk_gate_sbtx_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("CLK_GATE_SBTX_MON", "clk_gate_sbtx_cfg_obj not found in config_db for clk_gate_sbtx_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(clk_gate_sbtx_sequence_item t);
    seqr_item = clk_gate_sbtx_sequence_item::type_id::create("seqr_item");
    seqr_item.Load = t.Load;
    seqr_item.Enable = t.Enable;
    seqr_item.delay = t.delay;

  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = clk_gate_sbtx_sequence_item::type_id::create("seq_item");
      @(cfg.clk_gate_sbtx_vif.CLK or cfg.clk_gate_sbtx_vif.Enable or cfg.clk_gate_sbtx_vif.Load or cfg.clk_gate_sbtx_vif.SBTX_CLK);
      if(seqr_item)begin
        seq_item.delay <= seqr_item.delay;
        seq_item.Enable<=seqr_item.Enable;
        seq_item.Load<=seqr_item.Load;

      end
      seq_item.CLK<=cfg.clk_gate_sbtx_vif.CLK;
      // seq_item.Enable<=cfg.clk_gate_sbtx_vif.Enable;
      // seq_item.Load<=cfg.clk_gate_sbtx_vif.Load;
      seq_item.SBTX_CLK<=cfg.clk_gate_sbtx_vif.SBTX_CLK;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // CLK_GATE_SBTX_MONITOR_SVH
