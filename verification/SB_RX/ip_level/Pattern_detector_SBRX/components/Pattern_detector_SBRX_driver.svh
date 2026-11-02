`ifndef PATTERN_DETECTOR_SBRX_DRIVER_SVH
`define PATTERN_DETECTOR_SBRX_DRIVER_SVH

// Pattern_detector_SBRX_driver.svh
// Driver for the Pattern_detector_SBRX sub-environment.
// Drives stimulus on the Pattern_detector_SBRX virtual interface using Pattern_detector_SBRX_sequence_item.

class Pattern_detector_SBRX_driver extends uvm_driver #(Pattern_detector_SBRX_sequence_item);
  `uvm_component_utils(Pattern_detector_SBRX_driver)

  Pattern_detector_SBRX_sequence_item seq_item;
  Pattern_detector_SBRX_drv_mon_cfg_obj cfg;

  function new(string name = "Pattern_detector_SBRX_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(Pattern_detector_SBRX_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("PATTERN_DETECTOR_SBRX_DRV", "Pattern_detector_SBRX_drv_mon_cfg_obj not found in config_db for Pattern_detector_SBRX_driver")
    seq_item = Pattern_detector_SBRX_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(cfg.Pattern_detector_SBRX_vif.drv_cb);
      cfg.Pattern_detector_SBRX_vif.drv_cb.sb_sys_rst <= seq_item.sb_sys_rst;
      cfg.Pattern_detector_SBRX_vif.drv_cb.pattern_data_in <= seq_item.pattern_data_in;
      cfg.Pattern_detector_SBRX_vif.drv_cb.data_valid <= seq_item.data_valid;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // PATTERN_DETECTOR_SBRX_DRIVER_SVH
