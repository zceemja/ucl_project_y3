transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/src/blocks {/home/min/devel/fpga/ucl_project_y3/src/blocks/fifo.v}
vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/src/blocks {/home/min/devel/fpga/ucl_project_y3/src/blocks/uart.v}
vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/quartus {/home/min/devel/fpga/ucl_project_y3/quartus/pll_clk.v}
vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/db {/home/min/devel/fpga/ucl_project_y3/db/pll_clk_altpll.v}
vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/src/blocks {/home/min/devel/fpga/ucl_project_y3/src/blocks/rom.sv}
vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/src {/home/min/devel/fpga/ucl_project_y3/src/project.sv}
vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/src/blocks {/home/min/devel/fpga/ucl_project_y3/src/blocks/sdram_control.sv}
vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/src/blocks {/home/min/devel/fpga/ucl_project_y3/src/blocks/reg_file.sv}
vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/src/blocks {/home/min/devel/fpga/ucl_project_y3/src/blocks/alu.sv}
vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/src {/home/min/devel/fpga/ucl_project_y3/src/top.sv}
vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/src/risc {/home/min/devel/fpga/ucl_project_y3/src/risc/general.sv}
vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/src/risc {/home/min/devel/fpga/ucl_project_y3/src/risc/datapath.sv}
vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/src/risc {/home/min/devel/fpga/ucl_project_y3/src/risc/cpu.sv}
vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/src/risc {/home/min/devel/fpga/ucl_project_y3/src/risc/controller.sv}

vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/src {/home/min/devel/fpga/ucl_project_y3/src/top.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc"  top_tb

add wave *
view structure
view signals
run -all
