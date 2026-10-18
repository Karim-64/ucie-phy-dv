`ifndef MEM_MONITOR_SVH
`define MEM_MONITOR_SVH

class mem_monitor extends uvm_monitor;
  `uvm_component_utils(mem_monitor)

  mem_sequence_item seq_item;
  mem_sequence_item seqr_item;
  mem_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(mem_sequence_item, mem_monitor) mon_aimp;
  uvm_analysis_port#(mem_sequence_item) mon_aport;

  function new(string name = "mem_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(mem_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("MEM_MON", "mem_cfg_obj not found in config_db for mem_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(mem_sequence_item t);
    seqr_item = mem_sequence_item::type_id::create("seqr_item");
    seqr_item.rst = t.rst;
    seqr_item.cs = t.cs;
    seqr_item.we = t.we;
    seqr_item.addr = t.addr;
    seqr_item.data_in = t.data_in;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = mem_sequence_item::type_id::create("seq_item");
      @(cfg.mem_vif.mon_cb);
      if (seqr_item) begin
        seq_item.rst <= seqr_item.rst;
        seq_item.cs <= seqr_item.cs;
        seq_item.we <= seqr_item.we;
        seq_item.addr <= seqr_item.addr;
        seq_item.data_in <= seqr_item.data_in;
      end
      seq_item.data_out <= cfg.mem_vif.mon_cb.data_out;
      seq_item.valid_out <= cfg.mem_vif.mon_cb.valid_out;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // MEM_MONITOR_SVH
