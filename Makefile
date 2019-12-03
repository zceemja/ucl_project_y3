
QUARTUS_DIR = /opt/altera/18.1/quartus
MODELSIM_DIR = /opt/altera/18.1/modelsim_ase
PROJECT_NAME = UCL_project_y3
MODELSIM_GUI = ${QUARTUS_DIR}/bin/quartus_sh -t "${QUARTUS_DIR}/common/tcl/internal/nativelink/qnativesim.tcl" --rtl_sim "${PROJECT_NAME}" "${PROJECT_NAME}"
MODELSIM_BIN = ${MODELSIM_DIR}/bin/vsim
QUARTUS_MACROS =  --set VERILOG_MACRO="SYNTHESIS=1"

# OUTPUT FILES
OUTPUTP = output_files/$(PROJECT_NAME)
OUT_ASM = $(OUTPUTP).sof

# Program & Monitor
JTAG ?= 1
TTY  ?= /dev/ttyUSB0
BAUD ?= 9600

GENTABLE_BIN = python3 tools/gen_sv.py
ASMC = python3 tools/risc8asm.py

MEMSIZE ?= 4096
RAMSIZE ?= -1
MEMDEP := $(shell find memory -name '*.asm')
MEMSLICES = 0 1 2 3
MEMRES = $(foreach i,$(MEMSLICES),$(MEMDEP:.asm=.text_$(i).mem)) \
		$(foreach i,$(MEMSLICES),$(MEMDEP:.asm=.text_$(i).mif)) \
		$(foreach i,$(MEMSLICES),$(MEMDEP:.asm=.text_$(i).uhex)) \
		$(MEMDEP:.asm=.data.mem) \
		$(MEMDEP:.asm=.data.uhex) \
		$(MEMDEP:.asm=.data.mif)

VERILOG ?= $(wildcard src/*/*.sv) 

# Genreate sv case table from csv
CSVS = src/risc/controller.csv
define execute-gentable
$(GENTABLE_BIN) $(1) $(1:.csv=.sv)
endef

analysis: compile_mem
	${QUARTUS_DIR}/bin/quartus_map --read_settings_files=on --write_settings_files=off ${QUARTUS_MACROS} ${PROJECT_NAME} -c ${PROJECT_NAME} --analysis_and_elaboration

$(OUT_ASM): $(MEMDEP)
	${QUARTUS_DIR}/bin/quartus_map --read_settings_files=on --write_settings_files=off ${QUARTUS_MACROS} ${PROJECT_NAME} -c ${PROJECT_NAME} 
	${QUARTUS_DIR}/bin/quartus_fit --read_settings_files=off --write_settings_files=off ${QUARTUS_MACROS} ${PROJECT_NAME} -c ${PROJECT_NAME} 
	${QUARTUS_DIR}/bin/quartus_asm --read_settings_files=off --write_settings_files=off ${QUARTUS_MACROS} ${PROJECT_NAME} -c ${PROJECT_NAME} 

$(OUT_STA): $(OUT_ASM)
	${QUARTUS_DIR}/bin/quartus_sta ${PROJECT_NAME} -c ${PROJECT_NAME}

eda: $(OUT_STA)
	${QUARTUS_DIR}/bin/quartus_eda --read_settings_files=off --write_settings_files=off ${QUARTUS_MACROS} ${PROJECT_NAME} -c ${PROJECT_NAME} 

program: $(OUT_ASM)
	${QUARTUS_DIR}/bin/quartus_pgm -z -c $(JTAG) -m jtag -o "p;$(OUT_ASM)@1"

listdev:
	${QUARTUS_DIR}/bin/quartus_pgm -l

monitor:
	hash cu && echo "Escape with ~." && cu -l $(TTY) -s $(BAUD)
	#hash minicom && minicom -D $(TTY) -b $(BAUD)

modelsim_cli:
	${MODELSIM_BIN} -c

modelsim_gui:
	${MODELSIM_GUI}

compile_all:
	${MODELSIM_BIN} -c -do simulation/modelsim/${PROJECT_NAME}_run_msim_rtl_verilog.do -do exit

%.sv: %.csv $(CSVS)
	$(GENTABLE_BIN) $< $(@:.csv=.sv)

gentable:
	$(foreach x,$(CSVS),$(call execute-gentable,./$(x)))

compile: $(VERILOG)
	@echo ${MODELSIM_BIN} -c -do "vlog -sv -work work +incdir+$(abspath $(dir $<)) $(abspath $<)" -do exit
.PHONY: compile

testbench: compile
	${MODELSIM_BIN} -c -do "vsim work.$(basename $(notdir $(VERILOG)))_tb" -do "run -all" -do exit

compile_mem: $(MEMRES)

%.text_0.mem %.text_1.mem %.text_2.mem %.text_3.mem: %.asm
	$(ASMC) -t mem -f $< -S $(words $(MEMSLICES)) .text

%.text_0.mif %.text_1.mif %.text_2.mif %.text_3.mif: %.asm
	$(ASMC) -t mif -f $< -S $(words $(MEMSLICES)) .text

%.text_0.uhex %.text_1.uhex %.text_2.uhex %.text_3.uhex: %.asm
	$(ASMC) -t uhex -f $< -S $(words $(MEMSLICES)) .text

%.data.mem: %.asm
	$(ASMC) -t mem -f $< .data

%.data.mif: %.asm
	$(ASMC) -t mif -f $< .data

%.data.uhex: %.asm
	$(ASMC) -t uhex -f $< .data

flash: $(MEMRES)
	$(QUARTUS_DIR)/bin/quartus_stp -t ./scripts/update_risc8.tcl

clean:
	rm -f $(MEMRES)
	rm -f $(OUT_ASM)

#.PHONY: clean
