`ifndef CLK_GATE_SBTX_DRIVER_SVH
`define CLK_GATE_SBTX_DRIVER_SVH

// clk_gate_sbtx_driver.svh
// Driver for the clk_gate_sbtx sub-environment.
// Drives stimulus on the clk_gate_sbtx virtual interface using clk_gate_sbtx_sequence_item.

class clk_gate_sbtx_driver extends uvm_driver #(clk_gate_sbtx_sequence_item);
  `uvm_component_utils(clk_gate_sbtx_driver)

  clk_gate_sbtx_sequence_item seq_item;
  clk_gate_sbtx_drv_mon_cfg_obj cfg;

  function new(string name = "clk_gate_sbtx_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(clk_gate_sbtx_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("CLK_GATE_SBTX_DRV", "clk_gate_sbtx_drv_mon_cfg_obj not found in config_db for clk_gate_sbtx_driver")
    seq_item = clk_gate_sbtx_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(posedge cfg.clk_gate_sbtx_vif.CLK);
      if(seq_item.delay>0)begin
        #(seq_item.delay);
      end
      cfg.clk_gate_sbtx_vif.Load <= seq_item.Load;
      cfg.clk_gate_sbtx_vif.Enable <= seq_item.Enable;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // CLK_GATE_SBTX_DRIVER_SVH
