`ifndef FIFO_RD_MBRX_AGT_CFG_OBJ_SVH
`define FIFO_RD_MBRX_AGT_CFG_OBJ_SVH

class fifo_rd_mbrx_agt_cfg_obj extends uvm_object;
  `uvm_object_utils(fifo_rd_mbrx_agt_cfg_obj);

  virtual fifo_rd_mbrx_if#(P_SIZE) fifo_rd_mbrx_vif;
  uvm_active_passive_enum is_active;
  bit fifo_rd_mbrx_has_monitor;

  function new(string name = "fifo_rd_mbrx_agt_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // FIFO_RD_MBRX_AGT_CFG_OBJ_SVH
