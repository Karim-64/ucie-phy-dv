`ifndef MEM_DRV_MON_CFG_OBJ_SVH
`define MEM_DRV_MON_CFG_OBJ_SVH

class mem_drv_mon_cfg_obj extends uvm_object;
  `uvm_object_utils(mem_drv_mon_cfg_obj)

  virtual mem_if #(DATA_WIDTH, ADDRESS_WIDTH) mem_vif;

  function new(string name = "mem_drv_mon_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // MEM_DRV_MON_CFG_OBJ_SVH
