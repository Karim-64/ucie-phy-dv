`ifndef TIMER_MS_SBTX_DRV_MON_CFG_OBJ_SVH
`define TIMER_MS_SBTX_DRV_MON_CFG_OBJ_SVH

class Timer_ms_SBTX_drv_mon_cfg_obj extends uvm_object;
  `uvm_object_utils(Timer_ms_SBTX_drv_mon_cfg_obj)

  virtual Timer_ms_SBTX_if #(CLK_FREQ_HZ, FACTOR) Timer_ms_SBTX_vif;

  function new(string name = "Timer_ms_SBTX_drv_mon_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // TIMER_MS_SBTX_DRV_MON_CFG_OBJ_SVH
