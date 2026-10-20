`ifndef DATA_MUX_DRIVER_SVH
`define DATA_MUX_DRIVER_SVH

// Data_MUX_driver.svh
// Driver for the Data_MUX sub-environment.
// Drives stimulus on the Data_MUX virtual interface using Data_MUX_sequence_item.

class Data_MUX_driver extends uvm_driver #(Data_MUX_sequence_item);
  `uvm_component_utils(Data_MUX_driver)

  Data_MUX_sequence_item seq_item;
  Data_MUX_drv_mon_cfg_obj cfg;

  function new(string name = "Data_MUX_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(Data_MUX_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("DATA_MUX_DRV", "Data_MUX_drv_mon_cfg_obj not found in config_db for Data_MUX_driver")
    seq_item = Data_MUX_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(cfg.Data_MUX_vif.drv_cb);
      cfg.Data_MUX_vif.drv_cb.IN_0 <= seq_item.IN_0;
      cfg.Data_MUX_vif.drv_cb.IN_1 <= seq_item.IN_1;
      cfg.Data_MUX_vif.drv_cb.SEL_5 <= seq_item.SEL_5;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // DATA_MUX_DRIVER_SVH
