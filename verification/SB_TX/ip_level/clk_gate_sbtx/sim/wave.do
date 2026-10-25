onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_top/clk_gate_sbtx_if_inst/CLK
add wave -noupdate /tb_top/clk_gate_sbtx_if_inst/Enable
add wave -noupdate /tb_top/clk_gate_sbtx_if_inst/last_edge_time
add wave -noupdate /tb_top/clk_gate_sbtx_if_inst/Load
add wave -noupdate /tb_top/clk_gate_sbtx_if_inst/pulse_width
add wave -noupdate /tb_top/clk_gate_sbtx_if_inst/PULSE_WIDTH
add wave -noupdate /tb_top/clk_gate_sbtx_if_inst/SBTX_CLK
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {460014 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
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
WaveRestoreZoom {459351 ps} {461087 ps}
