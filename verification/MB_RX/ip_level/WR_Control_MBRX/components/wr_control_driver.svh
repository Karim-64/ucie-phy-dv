`ifndef WR_CONTROL_DRIVER_SVH
`define WR_CONTROL_DRIVER_SVH

// wr_control_driver.svh
// Driver for the wr_control sub-environment.
// Drives stimulus on the wr_control virtual interface using wr_control_sequence_item.

class wr_control_driver extends uvm_driver #(wr_control_sequence_item);
  `uvm_component_utils(wr_control_driver)

  wr_control_sequence_item seq_item;
  wr_control_drv_mon_cfg_obj cfg;

  function new(string name = "wr_control_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(wr_control_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("WR_CONTROL_DRV", "wr_control_drv_mon_cfg_obj not found in config_db for wr_control_driver")
    seq_item = wr_control_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(cfg.wr_control_vif.drv_cb);
      cfg.wr_control_vif.drv_cb.R_RST_n <= seq_item.R_RST_n;
      cfg.wr_control_vif.drv_cb.Ip_Bytes <= seq_item.Ip_Bytes;
      cfg.wr_control_vif.drv_cb.EN <= seq_item.EN;
      cfg.wr_control_vif.drv_cb.Deser_Done <= seq_item.Deser_Done;
      cfg.wr_control_vif.drv_cb.Width_Degrade <= seq_item.Width_Degrade;
      cfg.wr_control_vif.drv_cb.Width_Degrade_Update <= seq_item.Width_Degrade_Update;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // WR_CONTROL_DRIVER_SVH
