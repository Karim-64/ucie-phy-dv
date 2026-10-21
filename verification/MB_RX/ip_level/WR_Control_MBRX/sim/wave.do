onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group if /tb_top/wr_control_if_inst/CLK
add wave -noupdate -expand -group if /tb_top/wr_control_if_inst/R_RST_n
add wave -noupdate -expand -group if /tb_top/wr_control_if_inst/Ip_Bytes
add wave -noupdate -expand -group if /tb_top/wr_control_if_inst/EN
add wave -noupdate -expand -group if /tb_top/wr_control_if_inst/Deser_Done
add wave -noupdate -expand -group if -radix binary /tb_top/wr_control_if_inst/Width_Degrade
add wave -noupdate -expand -group if /tb_top/wr_control_if_inst/WR_EN
add wave -noupdate -expand -group if /tb_top/wr_control_if_inst/WR_DATA
add wave -noupdate -expand -group sb_exp @wr_control_scoreboard@1.exp_WR_DATA
add wave -noupdate -expand -group sb_exp @wr_control_scoreboard@1.exp_WR_EN
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {347000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
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
WaveRestoreZoom {0 ps} {5637 ps}
