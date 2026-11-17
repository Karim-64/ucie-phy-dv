`ifndef LFSR_PER_LANE_DRIVER_SVH
`define LFSR_PER_LANE_DRIVER_SVH

// lfsr_per_lane_driver.svh
// Driver for the lfsr_per_lane sub-environment.
// Drives stimulus on the lfsr_per_lane virtual interface using lfsr_per_lane_sequence_item.

class lfsr_per_lane_driver extends uvm_driver #(lfsr_per_lane_sequence_item);
  `uvm_component_utils(lfsr_per_lane_driver)

  lfsr_per_lane_sequence_item seq_item;
  lfsr_per_lane_drv_mon_cfg_obj cfg;

  function new(string name = "lfsr_per_lane_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(lfsr_per_lane_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("LFSR_PER_LANE_DRV", "lfsr_per_lane_drv_mon_cfg_obj not found in config_db for lfsr_per_lane_driver")
    seq_item = lfsr_per_lane_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(cfg.lfsr_per_lane_vif.drv_cb);
      cfg.lfsr_per_lane_vif.drv_cb.RST_n <= seq_item.RST_n;
      cfg.lfsr_per_lane_vif.drv_cb.Opcode_Synch <= seq_item.Opcode_Synch;
      cfg.lfsr_per_lane_vif.drv_cb.EN <= seq_item.EN;
      cfg.lfsr_per_lane_vif.drv_cb.PN_EN <= seq_item.PN_EN;
      cfg.lfsr_per_lane_vif.drv_cb.Data_In <= seq_item.Data_In;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // LFSR_PER_LANE_DRIVER_SVH
