`ifndef PAT_GEN_SBTX_DRIVER_SVH
`define PAT_GEN_SBTX_DRIVER_SVH

class pat_gen_sbtx_driver extends uvm_driver #(pat_gen_sbtx_sequence_item);
  `uvm_component_utils(pat_gen_sbtx_driver)

  pat_gen_sbtx_sequence_item seq_item;
  pat_gen_sbtx_drv_mon_cfg_obj cfg;
  virtual pat_gen_sbtx_if #() vif;

  function new(string name = "pat_gen_sbtx_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(pat_gen_sbtx_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("PAT_GEN_SBTX_DRV", "pat_gen_sbtx_drv_mon_cfg_obj not found in config_db for pat_gen_sbtx_driver")
    seq_item = pat_gen_sbtx_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    vif = cfg.pat_gen_sbtx_vif;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(vif.drv_cb);
      vif.drv_cb.RST_n       <= seq_item.RST_n;
      vif.drv_cb.Patt_Gen_En <= seq_item.Patt_Gen_En;

      seq_item_port.item_done();
    end
  endtask
endclass

`endif // PAT_GEN_SBTX_DRIVER_SVH
