`ifndef MUX_SBRX_DRIVER_SVH
`define MUX_SBRX_DRIVER_SVH

// mux_sbrx_driver.svh
// Driver for the mux_sbrx sub-environment.
// Drives stimulus on the mux_sbrx virtual interface using mux_sbrx_sequence_item.

class mux_sbrx_driver extends uvm_driver #(mux_sbrx_sequence_item);
  `uvm_component_utils(mux_sbrx_driver)

  mux_sbrx_sequence_item seq_item;
  mux_sbrx_drv_mon_cfg_obj cfg;

  function new(string name = "mux_sbrx_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(mux_sbrx_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("MUX_SBRX_DRV", "mux_sbrx_drv_mon_cfg_obj not found in config_db for mux_sbrx_driver")
    seq_item = mux_sbrx_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(cfg.mux_sbrx_vif.drv_cb);
      cfg.mux_sbrx_vif.drv_cb.in0 <= seq_item.in0;
      cfg.mux_sbrx_vif.drv_cb.in1 <= seq_item.in1;
      cfg.mux_sbrx_vif.drv_cb.sel <= seq_item.sel;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // MUX_SBRX_DRIVER_SVH
