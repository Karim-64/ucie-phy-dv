`ifndef GRAY_SYNCHRONIZER_SBTX_DRIVER_SVH
`define GRAY_SYNCHRONIZER_SBTX_DRIVER_SVH

// gray_synchronizer_sbtx_driver.svh
// Driver for the gray_synchronizer_sbtx sub-environment.
// Drives stimulus on the gray_synchronizer_sbtx virtual interface using gray_synchronizer_sbtx_sequence_item.

class gray_synchronizer_sbtx_driver extends uvm_driver #(gray_synchronizer_sbtx_sequence_item);
  `uvm_component_utils(gray_synchronizer_sbtx_driver)

  gray_synchronizer_sbtx_sequence_item seq_item;
  gray_synchronizer_sbtx_drv_mon_cfg_obj cfg;

  function new(string name = "gray_synchronizer_sbtx_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(gray_synchronizer_sbtx_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("GRAY_SYNCHRONIZER_SBTX_DRV", "gray_synchronizer_sbtx_drv_mon_cfg_obj not found in config_db for gray_synchronizer_sbtx_driver")
    seq_item = gray_synchronizer_sbtx_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(cfg.gray_synchronizer_sbtx_vif.drv_cb);
      cfg.gray_synchronizer_sbtx_vif.drv_cb.RST_n <= seq_item.RST_n;
      cfg.gray_synchronizer_sbtx_vif.drv_cb.Async_Data <= seq_item.Async_Data;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // GRAY_SYNCHRONIZER_SBTX_DRIVER_SVH
