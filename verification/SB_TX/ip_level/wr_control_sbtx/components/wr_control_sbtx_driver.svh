`ifndef WR_CONTROL_SBTX_DRIVER_SVH
`define WR_CONTROL_SBTX_DRIVER_SVH

// wr_control_sbtx_driver.svh
// Driver for the wr_control_sbtx sub-environment.
// Drives stimulus on the wr_control_sbtx virtual interface using wr_control_sbtx_sequence_item.

class wr_control_sbtx_driver extends uvm_driver #(wr_control_sbtx_sequence_item);
  `uvm_component_utils(wr_control_sbtx_driver)

  wr_control_sbtx_sequence_item seq_item;
  wr_control_sbtx_drv_mon_cfg_obj cfg;

  function new(string name = "wr_control_sbtx_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(wr_control_sbtx_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("WR_CONTROL_SBTX_DRV", "wr_control_sbtx_drv_mon_cfg_obj not found in config_db for wr_control_sbtx_driver")
    seq_item = wr_control_sbtx_sequence_item#()::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(cfg.wr_control_sbtx_vif.drv_cb);
      cfg.wr_control_sbtx_vif.drv_cb.RST_n <= seq_item.RST_n;
      cfg.wr_control_sbtx_vif.drv_cb.lp_cfg_vld <= seq_item.lp_cfg_vld;
      cfg.wr_control_sbtx_vif.drv_cb.lp_cfg <= seq_item.lp_cfg;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // WR_CONTROL_SBTX_DRIVER_SVH
