onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -label CLK /cpu_tb/clk
add wave -noupdate -label RST /cpu_tb/rst
add wave -noupdate -label PC /cpu_tb/CPU/pc
add wave -noupdate /cpu_tb/CPU/instr_op
add wave -noupdate -radix unsigned /cpu_tb/imm
add wave -noupdate -label RegFile -radix unsigned /cpu_tb/CPU/DPATH/RFILE/registry
add wave -noupdate -radix unsigned /cpu_tb/CPU/mem_addr
add wave -noupdate -label MemData -radix unsigned /cpu_tb/CPU/mem_wr_data
add wave -noupdate -label MemWr /cpu_tb/CPU/mem_wr_en
add wave -noupdate -radix ascii /cpu_tb/outvalue
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {48439 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 108
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
configure wave -timelineunits ns
update
WaveRestoreZoom {10275 ps} {78777 ps}
