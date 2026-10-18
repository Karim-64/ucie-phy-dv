`ifndef MEM_AGT_CFG_OBJ_SVH
`define MEM_AGT_CFG_OBJ_SVH

class mem_agt_cfg_obj extends uvm_object;
  `uvm_object_utils(mem_agt_cfg_obj);

  virtual mem_if#(DATA_WIDTH, ADDRESS_WIDTH) mem_vif;
  uvm_active_passive_enum is_active;
  bit mem_has_monitor;

  function new(string name = "mem_agt_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // MEM_AGT_CFG_OBJ_SVH
