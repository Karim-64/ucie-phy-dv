# ==============================================================================
# Questa Visualizer Wave Setup Script (dump_waves.do)
# ==============================================================================
# Usage (from sim/):
#   visualizer -designfile sim_runs/design.bin \
#              -wavefile sim_runs/<test_name>_seed<N>/waveform.qdb \
#              -do dump_waves.do
# ==============================================================================

# 1. Clock & Reset
wave add -group "Clock & Reset" \
    /tb_top/wr_control_sbtx_if_inst/CLK \
    /tb_top/wr_control_sbtx_if_inst/RST_n

# 2. DUT Inputs
wave add -group "DUT Inputs" \
    /tb_top/wr_control_sbtx_if_inst/lp_cfg_vld
wave add -group "DUT Inputs" -radix hex \
    /tb_top/wr_control_sbtx_if_inst/lp_cfg

# 3. DUT Outputs
wave add -group "DUT Outputs" \
    /tb_top/wr_control_sbtx_if_inst/FIFO_WR
wave add -group "DUT Outputs" -radix hex \
    /tb_top/wr_control_sbtx_if_inst/Interface_Message
wave add -group "DUT Outputs" \
    /tb_top/wr_control_sbtx_if_inst/Data_Marker \
    /tb_top/wr_control_sbtx_if_inst/Reg_Acc_Marker \
    /tb_top/wr_control_sbtx_if_inst/Reg_Acc_Data_Marker \
    /tb_top/wr_control_sbtx_if_inst/Comp_Marker \
    /tb_top/wr_control_sbtx_if_inst/Req_Resp_Marker \
    /tb_top/wr_control_sbtx_if_inst/Error_Handler \
    /tb_top/wr_control_sbtx_if_inst/UIE

wave zoom full
