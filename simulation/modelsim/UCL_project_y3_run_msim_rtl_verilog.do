transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/src {/home/min/devel/fpga/ucl_project_y3/src/general.sv}
vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/src {/home/min/devel/fpga/ucl_project_y3/src/datapath.sv}
vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/src/blocks {/home/min/devel/fpga/ucl_project_y3/src/blocks/instr_mem.sv}
vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/src {/home/min/devel/fpga/ucl_project_y3/src/cpu.sv}
vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/src/blocks {/home/min/devel/fpga/ucl_project_y3/src/blocks/reg_file.sv}
vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/src/blocks {/home/min/devel/fpga/ucl_project_y3/src/blocks/memory.sv}
vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/src/blocks {/home/min/devel/fpga/ucl_project_y3/src/blocks/alu.sv}
vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/src {/home/min/devel/fpga/ucl_project_y3/src/io_unit.sv}
vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/src {/home/min/devel/fpga/ucl_project_y3/src/controller.sv}

vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/src/blocks {/home/min/devel/fpga/ucl_project_y3/src/blocks/reg_file_tb.sv}
vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/src/blocks {/home/min/devel/fpga/ucl_project_y3/src/blocks/memory.sv}
vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/src/blocks {/home/min/devel/fpga/ucl_project_y3/src/blocks/alu.sv}
vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/src {/home/min/devel/fpga/ucl_project_y3/src/datapath.sv}
vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/src {/home/min/devel/fpga/ucl_project_y3/src/cpu.sv}
vlog -sv -work work +incdir+/home/min/devel/fpga/ucl_project_y3/src {/home/min/devel/fpga/ucl_project_y3/src/controller.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc"  testbench_1

add wave *
view structure
view signals
run -all
