`ifndef SYNCHRONIZER_SBRX_DRIVER_SVH
`define SYNCHRONIZER_SBRX_DRIVER_SVH

// Synchronizer_SBRX_driver.svh
// Driver for the Synchronizer_SBRX sub-environment.
// Drives stimulus on the Synchronizer_SBRX virtual interface using Synchronizer_SBRX_sequence_item.

class Synchronizer_SBRX_driver extends uvm_driver #(Synchronizer_SBRX_sequence_item);
  `uvm_component_utils(Synchronizer_SBRX_driver)

  Synchronizer_SBRX_sequence_item seq_item;
  Synchronizer_SBRX_drv_mon_cfg_obj cfg;

  function new(string name = "Synchronizer_SBRX_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(Synchronizer_SBRX_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("SYNCHRONIZER_SBRX_DRV", "Synchronizer_SBRX_drv_mon_cfg_obj not found in config_db for Synchronizer_SBRX_driver")
    seq_item = Synchronizer_SBRX_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(cfg.Synchronizer_SBRX_vif.drv_cb);
      cfg.Synchronizer_SBRX_vif.drv_cb.rst_n <= seq_item.rst_n;
      cfg.Synchronizer_SBRX_vif.drv_cb.signal_src <= seq_item.signal_src;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // SYNCHRONIZER_SBRX_DRIVER_SVH
