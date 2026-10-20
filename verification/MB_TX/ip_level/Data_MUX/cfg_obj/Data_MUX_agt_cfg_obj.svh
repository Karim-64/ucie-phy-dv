`ifndef DATA_MUX_AGT_CFG_OBJ_SVH
`define DATA_MUX_AGT_CFG_OBJ_SVH

class Data_MUX_agt_cfg_obj extends uvm_object;
  `uvm_object_utils(Data_MUX_agt_cfg_obj);

  virtual Data_MUX_if#() Data_MUX_vif;
  uvm_active_passive_enum is_active;
  bit Data_MUX_has_monitor;

  function new(string name = "Data_MUX_agt_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // DATA_MUX_AGT_CFG_OBJ_SVH
