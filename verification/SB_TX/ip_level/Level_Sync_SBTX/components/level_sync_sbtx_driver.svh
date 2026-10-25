`ifndef LEVEL_SYNC_SBTX_DRIVER_SVH
`define LEVEL_SYNC_SBTX_DRIVER_SVH

// level_sync_sbtx_driver.svh
// Driver for the level_sync_sbtx sub-environment.
// Drives stimulus on the level_sync_sbtx virtual interface using level_sync_sbtx_sequence_item.

class level_sync_sbtx_driver extends uvm_driver #(level_sync_sbtx_sequence_item);
  `uvm_component_utils(level_sync_sbtx_driver)

  level_sync_sbtx_sequence_item seq_item;
  level_sync_sbtx_drv_mon_cfg_obj cfg;

  function new(string name = "level_sync_sbtx_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(level_sync_sbtx_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("LEVEL_SYNC_SBTX_DRV", "level_sync_sbtx_drv_mon_cfg_obj not found in config_db for level_sync_sbtx_driver")
    seq_item = level_sync_sbtx_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(cfg.level_sync_sbtx_vif.drv_cb);
      cfg.level_sync_sbtx_vif.drv_cb.RST_n <= seq_item.RST_n;
      cfg.level_sync_sbtx_vif.drv_cb.Async_Signal <= seq_item.Async_Signal;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // LEVEL_SYNC_SBTX_DRIVER_SVH
