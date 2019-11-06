
QUARTUS_DIR = /opt/altera/18.1/quartus/bin
PROJECT_NAME = UCL_project_y3
QUARTUS_MAP = ${QUARTUS_DIR}/quartus_map --read_settings_files=on --write_settings_files=off ${PROJECT_NAME} -c ${PROJECT_NAME} 

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

gentable:
	$(foreach x,$(GENTABLE_CSV),$(call execute-gentable,./$(x)))

