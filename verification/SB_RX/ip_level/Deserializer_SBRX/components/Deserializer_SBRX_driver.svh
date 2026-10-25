`ifndef DESERIALIZER_SBRX_DRIVER_SVH
`define DESERIALIZER_SBRX_DRIVER_SVH

// Deserializer_SBRX_driver.svh
// Driver for the Deserializer_SBRX sub-environment.
// Drives stimulus on the Deserializer_SBRX virtual interface using Deserializer_SBRX_sequence_item.

class Deserializer_SBRX_driver extends uvm_driver #(Deserializer_SBRX_sequence_item);
  `uvm_component_utils(Deserializer_SBRX_driver)

  Deserializer_SBRX_sequence_item seq_item;
  Deserializer_SBRX_drv_mon_cfg_obj cfg;

  function new(string name = "Deserializer_SBRX_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(Deserializer_SBRX_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("DESERIALIZER_SBRX_DRV", "Deserializer_SBRX_drv_mon_cfg_obj not found in config_db for Deserializer_SBRX_driver")
    seq_item = Deserializer_SBRX_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(cfg.Deserializer_SBRX_vif.drv_cb);
      cfg.Deserializer_SBRX_vif.drv_cb.sb_sys_rst <= seq_item.sb_sys_rst;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // DESERIALIZER_SBRX_DRIVER_SVH
