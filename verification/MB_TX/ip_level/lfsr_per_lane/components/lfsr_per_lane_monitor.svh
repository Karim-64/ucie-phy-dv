`ifndef LFSR_PER_LANE_MONITOR_SVH
`define LFSR_PER_LANE_MONITOR_SVH

class lfsr_per_lane_monitor extends uvm_monitor;
  `uvm_component_utils(lfsr_per_lane_monitor)

  lfsr_per_lane_sequence_item seq_item;
  lfsr_per_lane_sequence_item seqr_item;
  lfsr_per_lane_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(lfsr_per_lane_sequence_item, lfsr_per_lane_monitor) mon_aimp;
  uvm_analysis_port#(lfsr_per_lane_sequence_item) mon_aport;

  function new(string name = "lfsr_per_lane_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(lfsr_per_lane_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("LFSR_PER_LANE_MON", "lfsr_per_lane_cfg_obj not found in config_db for lfsr_per_lane_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(lfsr_per_lane_sequence_item t);
    seqr_item = lfsr_per_lane_sequence_item::type_id::create("seqr_item");
    seqr_item.RST_n = t.RST_n;
    seqr_item.Opcode_Synch = t.Opcode_Synch;
    seqr_item.EN = t.EN;
    seqr_item.PN_EN = t.PN_EN;
    seqr_item.Data_In = t.Data_In;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = lfsr_per_lane_sequence_item::type_id::create("seq_item");
      @(cfg.lfsr_per_lane_vif.mon_cb);
      // Do not publish the power-up cycle(s) before the first stimulus has
      // been driven; all inputs/outputs are still X there.
      if (seqr_item == null)
        continue;
      seq_item.RST_n <= seqr_item.RST_n;
      seq_item.Opcode_Synch <= seqr_item.Opcode_Synch;
      seq_item.EN <= seqr_item.EN;
      seq_item.PN_EN <= seqr_item.PN_EN;
      seq_item.Data_In <= seqr_item.Data_In;
      seq_item.Data_Out <= cfg.lfsr_per_lane_vif.mon_cb.Data_Out;
      seq_item.Valid <= cfg.lfsr_per_lane_vif.mon_cb.Valid;
      seq_item.VLD_SER_EN <= cfg.lfsr_per_lane_vif.mon_cb.VLD_SER_EN;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // LFSR_PER_LANE_MONITOR_SVH
