
# Configuration
PROCESSOR ?= NONE  # Supported RISC8, OISC8
PROCESSOR_LOW = $(strip $(shell echo $(PROCESSOR) | tr A-Z a-z))

QUARTUS_DIR = /opt/altera/18.1/quartus
MODELSIM_DIR = /opt/altera/18.1/modelsim_ase
PROJECT_NAME = UCL_project_y3
MODELSIM_GUI = ${QUARTUS_DIR}/bin/quartus_sh -t "${QUARTUS_DIR}/common/tcl/internal/nativelink/qnativesim.tcl" --rtl_sim "${PROJECT_NAME}" "${PROJECT_NAME}"
MODELSIM_BIN = ${MODELSIM_DIR}/bin/vsim
QUARTUS_MACROS =  --set VERILOG_MACRO="SYNTHESIS=1"

# OUTPUT FILES
OUTPUTP = output_files/$(PROJECT_NAME)
OUT_ASM = $(OUTPUTP).sof

# assembly compiled and memory sliced files
BUILD_DIR = memory/build

# Program & Monitor
JTAG ?= 1
TTY  ?= /dev/ttyUSB0
BAUD ?= 9600

GENTABLE_BIN = python3 tools/gen_sv.py
ASMC = python3 tools/$(PROCESSOR_LOW)asm.py
FUTILS = python3 tools/format_utils.py

RAM_SIZE ?= 4096
RAM_WIDTH ?= 16

ASMDEP := $(shell find memory -name '*${PROCESSOR_LOW}.asm')
ifeq "${PROCESSOR_LOW}" "risc8"
MEMSLICES = 0 1 2 3
MEMTYPE = mem
TEXT_WIDTH = 8
else ifeq "${PROCESSOR_LOW}" "oisc8"
MEMSLICES = 0 1 2
MEMTYPE = binary
TEXT_WIDTH = 9
else
$(error "Processor not supported: ${PROCESSOR_LOW}")
endif

BUILD_OUT = $(addprefix ${BUILD_DIR}/,$(notdir $(ASMDEP:.asm=.text.o) $(ASMDEP:.asm=.data.o)))

MEM_BUILD =	$(addprefix ${BUILD_DIR}/,$(notdir $(ASMDEP:.asm=.data.mem) $(ASMDEP:.asm=.data.mif) $(foreach i,$(MEMSLICES),$(ASMDEP:.asm=.text.$(i).mem)) $(foreach i,$(MEMSLICES),$(ASMDEP:.asm=.text.$(i).mif)) ) )

#$(error MEM_BUILD: ${MEM_BUILD})
VERILOG ?= $(wildcard src/*/*.sv) 

# Genreate sv case table from csv
CSVS = src/risc/controller.csv
define execute-gentable
$(GENTABLE_BIN) $(1) $(1:.csv=.sv)
endef

analysis: $(MEM_BUILD)
	${QUARTUS_DIR}/bin/quartus_map --read_settings_files=on --write_settings_files=off ${QUARTUS_MACROS} ${PROJECT_NAME} -c ${PROJECT_NAME} --analysis_and_elaboration

$(OUT_ASM): $(ASMDEP)
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

simulate: $(VERILOG)
	@echo ${MODELSIM_BIN} -c -do "vlog -sv -work work +incdir+$(abspath $(dir $<)) $(abspath $<)" -do exit

.PHONY: compile

testbench: compile
	${MODELSIM_BIN} -c -do "vsim work.$(basename $(notdir $(VERILOG)))_tb" -do "run -all" -do exit

$(BUILD_DIR)/%.text.o $(BUILD_DIR)/%.data.o: $(ASMDEP)
	$(ASMC) $< -o $(BUILD_DIR) -f 

build: $(BUILD_OUT)

%.text.0.mem %.text.1.mem %.text.2.mem %.text.3.mem: %.text.o $(BUILD_OUT)
	$(FUTILS) -w $(TEXT_WIDTH) -t memb -f -S $(words $(MEMSLICES)) $<

%.text.0.mif %.text.1.mif %.text.2.mif %.text.3.mif: %.text.o $(BUILD_OUT)
	$(FUTILS) -w $(TEXT_WIDTH) -t mif -f -S $(words $(MEMSLICES)) $<

%.data.mem: %.data.o $(BUILD_OUT)
	$(FUTILS) -w $(RAM_WIDTH) -t memh -f $<

%.data.mif: %.data.o $(BUILD_OUT)
	$(FUTILS) -w $(RAM_WIDTH) -t mif -f $<

%.text.mem: %.text.o $(BUILD_OUT)
	$(ASMC) -t mem -f $< .text

%.text.mif: %.text.o $(BUILD_OUT)
	$(ASMC) -t mif -f $< .text

memory: $(MEM_BUID)

flash: $(BUILD_OUT)
	$(QUARTUS_DIR)/bin/quartus_stp -t ./scripts/update_$(PROCESSOR_LOW).tcl

clean:
	rm -f $(MEMRES)
	rm -f $(OUT_ASM)

#.PHONY: clean
