`ifndef TIMER_SBTX_DRIVER_SVH
`define TIMER_SBTX_DRIVER_SVH

// Timer_SBTX_driver.svh
// Driver for the Timer_SBTX sub-environment.
// Drives stimulus on the Timer_SBTX virtual interface using Timer_SBTX_sequence_item.

class Timer_SBTX_driver extends uvm_driver #(Timer_SBTX_sequence_item);
  `uvm_component_utils(Timer_SBTX_driver)

  Timer_SBTX_sequence_item seq_item;
  Timer_SBTX_drv_mon_cfg_obj cfg;

  function new(string name = "Timer_SBTX_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(Timer_SBTX_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("TIMER_SBTX_DRV", "Timer_SBTX_drv_mon_cfg_obj not found in config_db for Timer_SBTX_driver")
    seq_item = Timer_SBTX_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(cfg.Timer_SBTX_vif.drv_cb);
      cfg.Timer_SBTX_vif.drv_cb.rst_n <= seq_item.rst_n;
      cfg.Timer_SBTX_vif.drv_cb.start <= seq_item.start;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // TIMER_SBTX_DRIVER_SVH
