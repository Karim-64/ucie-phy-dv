onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_top/Enable_Generator_MBRX_if_inst/CLK
add wave -noupdate /tb_top/Enable_Generator_MBRX_if_inst/RST_n
add wave -noupdate /tb_top/Enable_Generator_MBRX_if_inst/LTSM_State
add wave -noupdate /tb_top/Enable_Generator_MBRX_if_inst/Width_Degrade
add wave -noupdate /tb_top/Enable_Generator_MBRX_if_inst/Valid
add wave -noupdate /tb_top/Enable_Generator_MBRX_if_inst/Comparison_Done
add wave -noupdate /tb_top/Enable_Generator_MBRX_if_inst/Valid_Frame_Error
add wave -noupdate /tb_top/Enable_Generator_MBRX_if_inst/Detec_succ
add wave -noupdate /tb_top/Enable_Generator_MBRX_if_inst/Test_Resp
add wave -noupdate /tb_top/Enable_Generator_MBRX_if_inst/Vchk_EN
add wave -noupdate /tb_top/Enable_Generator_MBRX_if_inst/Descr_EN
add wave -noupdate /tb_top/Enable_Generator_MBRX_if_inst/Deserializer_EN1
add wave -noupdate /tb_top/Enable_Generator_MBRX_if_inst/Deserializer_EN2
add wave -noupdate /tb_top/Enable_Generator_MBRX_if_inst/Data_Comparator_EN
add wave -noupdate /tb_top/Enable_Generator_MBRX_if_inst/Valid_Detected
add wave -noupdate /tb_top/Enable_Generator_MBRX_if_inst/Comparison_Type
add wave -noupdate /tb_top/Enable_Generator_MBRX_if_inst/LFSR_SEL
add wave -noupdate /tb_top/dut/Chunk_Marker
add wave -noupdate /tb_top/dut/Test_Resp_latched
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {20247 ps} 0}
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
WaveRestoreZoom {20175 ps} {20888 ps}
