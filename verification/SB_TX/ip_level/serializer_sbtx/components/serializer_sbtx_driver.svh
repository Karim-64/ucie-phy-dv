`ifndef SERIALIZER_SBTX_DRIVER_SVH
`define SERIALIZER_SBTX_DRIVER_SVH

// serializer_sbtx_driver.svh
// Driver for the serializer_sbtx sub-environment.
// Drives stimulus on the serializer_sbtx virtual interface using serializer_sbtx_sequence_item.

class serializer_sbtx_driver extends uvm_driver #(serializer_sbtx_sequence_item);
  `uvm_component_utils(serializer_sbtx_driver)

  serializer_sbtx_sequence_item seq_item;
  serializer_sbtx_drv_mon_cfg_obj cfg;

  function new(string name = "serializer_sbtx_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(serializer_sbtx_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("SERIALIZER_SBTX_DRV", "serializer_sbtx_drv_mon_cfg_obj not found in config_db for serializer_sbtx_driver")
    seq_item = serializer_sbtx_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(cfg.serializer_sbtx_vif.drv_cb);
      cfg.serializer_sbtx_vif.drv_cb.rst_n <= seq_item.rst_n;
      cfg.serializer_sbtx_vif.drv_cb.load <= seq_item.load;
      cfg.serializer_sbtx_vif.drv_cb.Enable <= seq_item.Enable;
      cfg.serializer_sbtx_vif.drv_cb.data_in <= seq_item.data_in;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // SERIALIZER_SBTX_DRIVER_SVH
