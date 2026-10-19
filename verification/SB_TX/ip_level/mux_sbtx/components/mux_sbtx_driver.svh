`ifndef MUX_SBTX_DRIVER_SVH
`define MUX_SBTX_DRIVER_SVH

// mux_sbtx_driver.svh
// Driver for the mux_sbtx sub-environment.
// Drives stimulus on the mux_sbtx virtual interface using mux_sbtx_sequence_item.

class mux_sbtx_driver extends uvm_driver #(mux_sbtx_sequence_item);
  `uvm_component_utils(mux_sbtx_driver)

  mux_sbtx_sequence_item seq_item;
  mux_sbtx_drv_mon_cfg_obj cfg;

  function new(string name = "mux_sbtx_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(mux_sbtx_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("MUX_SBTX_DRV", "mux_sbtx_drv_mon_cfg_obj not found in config_db for mux_sbtx_driver")
    seq_item = mux_sbtx_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(cfg.mux_sbtx_vif.drv_cb);
      cfg.mux_sbtx_vif.drv_cb.IN_0 <= seq_item.IN_0;
      cfg.mux_sbtx_vif.drv_cb.IN_1 <= seq_item.IN_1;
      cfg.mux_sbtx_vif.drv_cb.Mux_Sel <= seq_item.Mux_Sel;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // MUX_SBTX_DRIVER_SVH
