onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -label Clock /risc8_cpu_tb/clk
add wave -noupdate -label Reset /risc8_cpu_tb/rst
add wave -noupdate -label ProgramCount -radix unsigned /risc8_cpu_tb/cpu0/pc
add wave -noupdate -label RegisterFile -radix hexadecimal /risc8_cpu_tb/cpu0/dpath0/reg0/registry
add wave -noupdate -label Instruction /risc8_cpu_tb/cpu0/ctrl0/op
add wave -noupdate /risc8_cpu_tb/cpu0/ctrl0/instr
add wave -noupdate -label r1 -radix hexadecimal /risc8_cpu_tb/cpu0/dpath0/r1
add wave -noupdate -label RamAddr /risc8_cpu_tb/ram_addr
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {512 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 157
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
WaveRestoreZoom {461 ns} {524 ns}
