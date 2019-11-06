
QUARTUS_DIR = /opt/altera/18.1/quartus
MODELSIM_DIR = /opt/altera/18.1/modelsim_ase
PROJECT_NAME = UCL_project_y3
QUARTUS_MAP = ${QUARTUS_DIR}/bin/quartus_map --read_settings_files=on --write_settings_files=off ${PROJECT_NAME} -c ${PROJECT_NAME} 
MODELSIM_GUI = ${QUARTUS_DIR}/bin/quartus_sh -t "${QUARTUS_DIR}/common/tcl/internal/nativelink/qnativesim.tcl" --rtl_sim "${PROJECT_NAME}" "${PROJECT_NAME}"
MODELSIM_BIN = ${MODELSIM_DIR}/bin/vsim


# Genreate sv case table from csv
GENSV = python3 tools/gen_sv.py
GENTABLE_CSV = src/risc/controller.csv
define execute-gentable
$(GENSV) $(1) $(1:.csv=.sv)
endef

analysis:
	${QUARTUS_MAP} --analysis_and_elaboration

synthesis:
	${QUARTUS_MAP}

modelsim_cli:
	${MODELSIM_BIN} -c

modelsim_gui:
	${MODELSIM_GUI}

compile:
	${MODELSIM_BIN} -c -do simulation/modelsim/${PROJECT_NAME}_run_msim_rtl_verilog.do -do exit

gentable:
	$(foreach x,$(GENTABLE_CSV),$(call execute-gentable,./$(x)))

