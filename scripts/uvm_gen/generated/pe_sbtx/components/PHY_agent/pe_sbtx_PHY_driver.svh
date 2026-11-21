`ifndef PE_SBTX_PHY_DRIVER_SVH
`define PE_SBTX_PHY_DRIVER_SVH

class pe_sbtx_PHY_driver extends uvm_driver #(pe_sbtx_PHY_sequence_item);
  `uvm_component_utils(pe_sbtx_PHY_driver)

  pe_sbtx_PHY_sequence_item seq_item;
  pe_sbtx_PHY_drv_mon_cfg_obj cfg;

  function new(string name = "pe_sbtx_PHY_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(pe_sbtx_PHY_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("PE_SBTX_PHY_DRV", "pe_sbtx_PHY_drv_mon_cfg_obj not found in config_db for pe_sbtx_PHY_driver")
    seq_item = pe_sbtx_PHY_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(cfg.pe_sbtx_vif.drv_cb);
      cfg.pe_sbtx_vif.drv_cb.rst_n <= seq_item.rst_n;
      cfg.pe_sbtx_vif.drv_cb.en <= seq_item.en;
      cfg.pe_sbtx_vif.drv_cb.data_marker <= seq_item.data_marker;
      cfg.pe_sbtx_vif.drv_cb.comp_marker <= seq_item.comp_marker;
      cfg.pe_sbtx_vif.drv_cb.data <= seq_item.data;

      seq_item_port.item_done();
    end
  endtask
endclass

`endif // PE_SBTX_PHY_DRIVER_SVH
