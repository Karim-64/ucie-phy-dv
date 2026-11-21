`ifndef WR_CONTROL_AGT_CFG_OBJ_SVH
`define WR_CONTROL_AGT_CFG_OBJ_SVH

class wr_control_agt_cfg_obj extends uvm_object;
  `uvm_object_utils(wr_control_agt_cfg_obj);

  virtual wr_control_if#(W_D_SIZE, WIDTH_DEGRADE_LENGTH) wr_control_vif;
  uvm_active_passive_enum is_active;
  bit wr_control_has_monitor;

  function new(string name = "wr_control_agt_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // WR_CONTROL_AGT_CFG_OBJ_SVH
