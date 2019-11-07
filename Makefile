
QUARTUS_DIR = /opt/altera/18.1/quartus
MODELSIM_DIR = /opt/altera/18.1/modelsim_ase
PROJECT_NAME = UCL_project_y3
QUARTUS_MAP = ${QUARTUS_DIR}/bin/quartus_map --read_settings_files=on --write_settings_files=off ${PROJECT_NAME} -c ${PROJECT_NAME} 
MODELSIM_GUI = ${QUARTUS_DIR}/bin/quartus_sh -t "${QUARTUS_DIR}/common/tcl/internal/nativelink/qnativesim.tcl" --rtl_sim "${PROJECT_NAME}" "${PROJECT_NAME}"
MODELSIM_BIN = ${MODELSIM_DIR}/bin/vsim

GENTABLE_BIN = python3 tools/gen_sv.py
ASMC = python3 tools/asm_compiler.py

MEMDEP = memory/risc8_test.asm
MEMRES = $(MEMDEP:.asm=.mem)

# Genreate sv case table from csv
GENTABLE_CSV = src/risc/controller.csv
define execute-gentable
$(GENTABLE_BIN) $(1) $(1:.csv=.sv)
endef

analysis: compile_mem
	${QUARTUS_MAP} --analysis_and_elaboration

synthesis:
	${QUARTUS_MAP}

modelsim_cli:
	${MODELSIM_BIN} -c

modelsim_gui:
	${MODELSIM_GUI}

compile:
	${MODELSIM_BIN} -c -do simulation/modelsim/${PROJECT_NAME}_run_msim_rtl_verilog.do -do exit

compile_mem: $(MEMRES)

%.mem: $(MEMDEP) 
	${ASMC} -t mem -o $@ -f $<

gentable:
	$(foreach x,$(GENTABLE_CSV),$(call execute-gentable,./$(x)))

clean:
	rm -f $(MEMRES)

.PHONY: clean
