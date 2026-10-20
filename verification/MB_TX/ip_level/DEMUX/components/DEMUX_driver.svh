`ifndef DEMUX_DRIVER_SVH
`define DEMUX_DRIVER_SVH

// DEMUX_driver.svh
// Driver for the DEMUX sub-environment.
// Drives stimulus on the DEMUX virtual interface using DEMUX_sequence_item.

class DEMUX_driver extends uvm_driver #(DEMUX_sequence_item);
  `uvm_component_utils(DEMUX_driver)

  DEMUX_sequence_item seq_item;
  DEMUX_drv_mon_cfg_obj cfg;

  function new(string name = "DEMUX_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(DEMUX_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("DEMUX_DRV", "DEMUX_drv_mon_cfg_obj not found in config_db for DEMUX_driver")
    seq_item = DEMUX_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(cfg.DEMUX_vif.drv_cb);
      cfg.DEMUX_vif.drv_cb.lp_data <= seq_item.lp_data;
      cfg.DEMUX_vif.drv_cb.SEL_4 <= seq_item.SEL_4;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // DEMUX_DRIVER_SVH
