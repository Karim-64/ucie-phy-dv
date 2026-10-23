onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_top/wr_control_sbtx_if_inst/CLK
add wave -noupdate /tb_top/wr_control_sbtx_if_inst/Comp_Marker
add wave -noupdate /tb_top/wr_control_sbtx_if_inst/Comp_Marker_exp
add wave -noupdate /tb_top/wr_control_sbtx_if_inst/Data_Marker
add wave -noupdate /tb_top/wr_control_sbtx_if_inst/Data_Marker_exp
add wave -noupdate /tb_top/wr_control_sbtx_if_inst/Error_Handler
add wave -noupdate /tb_top/wr_control_sbtx_if_inst/Error_Handler_exp
add wave -noupdate /tb_top/wr_control_sbtx_if_inst/FIFO_WR
add wave -noupdate /tb_top/wr_control_sbtx_if_inst/Interface_Message
add wave -noupdate /tb_top/wr_control_sbtx_if_inst/FIFO_WR_exp
add wave -noupdate /tb_top/wr_control_sbtx_if_inst/Interface_Message_exp
add wave -noupdate /tb_top/wr_control_sbtx_if_inst/lp_cfg
add wave -noupdate -color Magenta /tb_top/wr_control_sbtx_if_inst/lp_cfg_vld
add wave -noupdate /tb_top/wr_control_sbtx_if_inst/NC
add wave -noupdate /tb_top/wr_control_sbtx_if_inst/Reg_Acc_Data_Marker
add wave -noupdate /tb_top/wr_control_sbtx_if_inst/Reg_Acc_Data_Marker_exp
add wave -noupdate /tb_top/wr_control_sbtx_if_inst/Reg_Acc_Marker
add wave -noupdate /tb_top/wr_control_sbtx_if_inst/Reg_Acc_Marker_exp
add wave -noupdate /tb_top/wr_control_sbtx_if_inst/Req_Resp_Marker
add wave -noupdate /tb_top/wr_control_sbtx_if_inst/Req_Resp_Marker_exp
add wave -noupdate -color {Blue Violet} /tb_top/wr_control_sbtx_if_inst/RST_n
add wave -noupdate /tb_top/wr_control_sbtx_if_inst/UIE
add wave -noupdate /tb_top/wr_control_sbtx_if_inst/UIE_exp
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {86330 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 193
configure wave -valuecolwidth 82
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {10546 ps}
