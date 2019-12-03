onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /top_tb/CLK50
add wave -noupdate -label MCLK /top_tb/top0/cpu_block0/dpath0/clk
add wave -noupdate -label RESET /top_tb/top0/cpu_block0/dpath0/rst
add wave -noupdate -label PC_FF -radix hexadecimal /top_tb/top0/cpu_block0/rom_block0/ff_addr
add wave -noupdate -group PC -label PC -radix hexadecimal /top_tb/top0/cpu_block0/dpath0/pc
add wave -noupdate -group PC -label PCX -radix hexadecimal -radixshowbase 0 /top_tb/top0/cpu_block0/dpath0/pcx
add wave -noupdate -group PC -label PC_OFF -radix unsigned -radixshowbase 0 /top_tb/top0/cpu_block0/dpath0/pc_off
add wave -noupdate -group PC /top_tb/top0/cpu_block0/cdi0/pcop
add wave -noupdate -label operation /top_tb/top0/cpu_block0/ctrl0/op
add wave -noupdate -color {Cadet Blue} -label REG_FILE -radix hexadecimal /top_tb/top0/cpu_block0/dpath0/reg0/registry
add wave -noupdate -expand -group ALU -label ALU_OP /top_tb/top0/cpu_block0/cdi0/alu_op
add wave -noupdate -expand -group ALU -label SRC_A -radix hexadecimal /top_tb/top0/cpu_block0/dpath0/srcA
add wave -noupdate -expand -group ALU -label SRC_B -radix hexadecimal /top_tb/top0/cpu_block0/dpath0/srcB
add wave -noupdate -expand -group ALU -label ALU_EQ /top_tb/top0/cpu_block0/dpath0/alu_eq
add wave -noupdate -expand -group ALU -label ALU_GT /top_tb/top0/cpu_block0/dpath0/alu_gt
add wave -noupdate -expand -group ALU -label ALU_ZERO /top_tb/top0/cpu_block0/dpath0/alu_zero
add wave -noupdate -expand -group ALU -label ALU_R_Lo -radix hexadecimal /top_tb/top0/cpu_block0/dpath0/alu_rlo
add wave -noupdate -expand -group ALU -label ALU_R_Hi -radix hexadecimal /top_tb/top0/cpu_block0/dpath0/alu_rhi
add wave -noupdate -expand -group COMS -label COM_ADDR -radix hexadecimal /top_tb/top0/port0/com_addr
add wave -noupdate -expand -group COMS -label COM_WR -radix hexadecimal /top_tb/top0/port0/com_wr
add wave -noupdate -expand -group COMS -label COM_RD -radix hexadecimal -childformat {{{/top_tb/top0/port0/com_rd[7]} -radix hexadecimal} {{/top_tb/top0/port0/com_rd[6]} -radix hexadecimal} {{/top_tb/top0/port0/com_rd[5]} -radix hexadecimal} {{/top_tb/top0/port0/com_rd[4]} -radix hexadecimal} {{/top_tb/top0/port0/com_rd[3]} -radix hexadecimal} {{/top_tb/top0/port0/com_rd[2]} -radix hexadecimal} {{/top_tb/top0/port0/com_rd[1]} -radix hexadecimal} {{/top_tb/top0/port0/com_rd[0]} -radix hexadecimal}} -subitemconfig {{/top_tb/top0/port0/com_rd[7]} {-height 17 -radix hexadecimal} {/top_tb/top0/port0/com_rd[6]} {-height 17 -radix hexadecimal} {/top_tb/top0/port0/com_rd[5]} {-height 17 -radix hexadecimal} {/top_tb/top0/port0/com_rd[4]} {-height 17 -radix hexadecimal} {/top_tb/top0/port0/com_rd[3]} {-height 17 -radix hexadecimal} {/top_tb/top0/port0/com_rd[2]} {-height 17 -radix hexadecimal} {/top_tb/top0/port0/com_rd[1]} {-height 17 -radix hexadecimal} {/top_tb/top0/port0/com_rd[0]} {-height 17 -radix hexadecimal}} /top_tb/top0/port0/com_rd
add wave -noupdate -expand -group COMS /top_tb/SWITCH
add wave -noupdate -expand -group COMS /top_tb/LED
add wave -noupdate -expand -group MEMORY -color Sienna -label RAM_ADDR -radix hexadecimal /top_tb/top0/port0/ram_addr
add wave -noupdate -expand -group MEMORY -color Sienna -label RAM_WR -radix hexadecimal /top_tb/top0/port0/ram_wr_data
add wave -noupdate -expand -group MEMORY -color Sienna -label RAM_RD -radix hexadecimal /top_tb/top0/port0/ram_rd_data
add wave -noupdate -expand -group MEMORY -color Sienna -label RAM_WRE /top_tb/top0/port0/ram_wr_en
add wave -noupdate -expand -group MEMORY -color Sienna -label RAM_RDE /top_tb/top0/port0/ram_rd_en
add wave -noupdate -expand -group MEMORY -label state /top_tb/top0/sdram0/state
add wave -noupdate -expand -group MEMORY -label rd_ready /top_tb/top0/sdram0/sdram_control0/rd_ready
add wave -noupdate -expand -group MEMORY -label busy /top_tb/top0/sdram0/sdram_control0/busy
add wave -noupdate -expand -group MEMORY -label wr_en /top_tb/top0/sdram0/sdram_control0/wr_enable
add wave -noupdate -expand -group MEMORY -label rd_en /top_tb/top0/sdram0/sdram_control0/rd_enable
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {3529488 ps} 0}
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
WaveRestoreZoom {0 ps} {10361984 ps}
