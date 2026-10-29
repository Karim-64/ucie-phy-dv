`ifndef SERIALIZER_DRIVER_SVH
`define SERIALIZER_DRIVER_SVH

// Serializer_driver.svh
// Driver for the Serializer sub-environment.
// Drives stimulus on the Serializer virtual interface using Serializer_sequence_item.

class Serializer_driver extends uvm_driver #(Serializer_sequence_item);
  `uvm_component_utils(Serializer_driver)

  Serializer_sequence_item seq_item;
  Serializer_drv_mon_cfg_obj cfg;

  function new(string name = "Serializer_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(Serializer_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("SERIALIZER_DRV", "Serializer_drv_mon_cfg_obj not found in config_db for Serializer_driver")
    seq_item = Serializer_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(cfg.Serializer_vif.drv_cb);
      cfg.Serializer_vif.drv_cb.SER_EN <= seq_item.SER_EN;
      cfg.Serializer_vif.drv_cb.DATA <= seq_item.DATA;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // SERIALIZER_DRIVER_SVH
