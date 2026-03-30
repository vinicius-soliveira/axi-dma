SHELL := /bin/bash

ROOT_DIR := $(CURDIR)
RTL_DIR := $(ROOT_DIR)/rtl
SCRIPT_DIR := $(ROOT_DIR)/scripts
TB_DIR := $(ROOT_DIR)/tb
SYNTH_DIR := $(ROOT_DIR)/synth
GENUS_OUT := $(SYNTH_DIR)/genus
GLS_DIR := $(ROOT_DIR)/gls

TOP := dma_axi_top

# Tools
YOSYS ?= yosys
STA ?= sta
IVERILOG ?= iverilog
VVP ?= vvp
GENUS ?= genus

# SKY130 defaults (customize if needed)
SKY130_PDK_ROOT ?= /home/vinicius.silva/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af
SKY130_LIB_DEFAULT := $(SKY130_PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
LIB_FILES ?= $(SKY130_LIB_DEFAULT)

# Common paths
SDC_FILE := $(SYNTH_DIR)/constraints/$(TOP).sdc
GENERIC_NETLIST := $(SYNTH_DIR)/netlist/$(TOP)_netlist.v
SKY130_NETLIST := $(SYNTH_DIR)/netlist/$(TOP)_netlist_sky130.v
SDF_FILE := $(SYNTH_DIR)/netlist/$(TOP).sdf

.PHONY: help env dirs \
        synth synth-sky130 sta \
        gls gls-generic gls-sky130 \
        genus genus-check \
        reports all clean clean-gls clean-genus clean-synth

help:
	@echo "Unified build flow for axi_dma"
	@echo ""
	@echo "Targets:"
	@echo "  make env           - print key environment variables and paths"
	@echo "  make dirs          - create output directories"
	@echo "  make synth         - run generic Yosys synthesis"
	@echo "  make synth-sky130  - run SKY130-mapped Yosys synthesis"
	@echo "  make sta           - run OpenSTA timing analysis"
	@echo "  make gls-generic   - run GLS with generic netlist"
	@echo "  make gls-sky130    - run GLS with SKY130-mapped netlist"
	@echo "  make gls           - alias for gls-generic"
	@echo "  make genus         - run Cadence Genus synthesis flow"
	@echo "  make reports       - show report and log locations"
	@echo "  make all           - synth-sky130 + sta + gls-generic"
	@echo "  make clean         - remove generated artifacts"
	@echo ""
	@echo "Typical usage:"
	@echo "  make synth-sky130"
	@echo "  make sta"
	@echo "  make gls-generic"
	@echo "  make genus"

env:
	@echo "ROOT_DIR         = $(ROOT_DIR)"
	@echo "RTL_DIR          = $(RTL_DIR)"
	@echo "SCRIPT_DIR       = $(SCRIPT_DIR)"
	@echo "SYNTH_DIR        = $(SYNTH_DIR)"
	@echo "GENUS_OUT        = $(GENUS_OUT)"
	@echo "GLS_DIR          = $(GLS_DIR)"
	@echo "TOP              = $(TOP)"
	@echo "SKY130_PDK_ROOT  = $(SKY130_PDK_ROOT)"
	@echo "LIB_FILES        = $(LIB_FILES)"
	@echo "SDC_FILE         = $(SDC_FILE)"
	@echo "GENERIC_NETLIST  = $(GENERIC_NETLIST)"
	@echo "SKY130_NETLIST   = $(SKY130_NETLIST)"
	@echo "SDF_FILE         = $(SDF_FILE)"

dirs:
	mkdir -p $(SYNTH_DIR)/logs $(SYNTH_DIR)/reports $(SYNTH_DIR)/netlist $(SYNTH_DIR)/constraints
	mkdir -p $(GLS_DIR)/build $(GLS_DIR)/logs
	mkdir -p $(GENUS_OUT)/logs $(GENUS_OUT)/reports $(GENUS_OUT)/netlist $(GENUS_OUT)/db

synth: dirs
	@test -f $(SCRIPT_DIR)/synth.ys || { echo "Missing $(SCRIPT_DIR)/synth.ys"; exit 1; }
	$(YOSYS) -s $(SCRIPT_DIR)/synth.ys | tee $(SYNTH_DIR)/logs/synth.log

synth-sky130: dirs
	@test -f $(SCRIPT_DIR)/synth_sky130.ys || { echo "Missing $(SCRIPT_DIR)/synth_sky130.ys"; exit 1; }
	$(YOSYS) -s $(SCRIPT_DIR)/synth_sky130.ys | tee $(SYNTH_DIR)/logs/synth_sky130.log

sta: dirs
	@test -f $(SCRIPT_DIR)/sta.tcl || { echo "Missing $(SCRIPT_DIR)/sta.tcl"; exit 1; }
	$(STA) $(SCRIPT_DIR)/sta.tcl | tee $(SYNTH_DIR)/logs/sta.log

gls-generic: dirs
	@test -x $(SCRIPT_DIR)/run_gls_generic.sh || chmod +x $(SCRIPT_DIR)/run_gls_generic.sh
	$(SCRIPT_DIR)/run_gls_generic.sh

gls-sky130: dirs
	@test -x $(SCRIPT_DIR)/run_gls.sh || chmod +x $(SCRIPT_DIR)/run_gls.sh
	$(SCRIPT_DIR)/run_gls.sh

gls: gls-generic

genus-check:
	@test -f $(SCRIPT_DIR)/genus.tcl || { echo "Missing $(SCRIPT_DIR)/genus.tcl"; exit 1; }
	@test -x $(SCRIPT_DIR)/run_genus.sh || chmod +x $(SCRIPT_DIR)/run_genus.sh
	@test -f "$(LIB_FILES)" || { \
		echo "Liberty file not found: $(LIB_FILES)"; \
		echo "Adjust SKY130_PDK_ROOT or LIB_FILES."; \
		exit 2; \
	}

genus: dirs genus-check
	SKY130_PDK_ROOT="$(SKY130_PDK_ROOT)" \
	LIB_FILES="$(LIB_FILES)" \
	TOP_MODULE="$(TOP)" \
	RTL_DIR="$(RTL_DIR)" \
	CONSTRAINTS_FILE="$(SDC_FILE)" \
	OUT_DIR="$(GENUS_OUT)" \
	$(SCRIPT_DIR)/run_genus.sh

reports:
	@echo "Open-source synthesis reports:"
	@echo "  Logs    : $(SYNTH_DIR)/logs"
	@echo "  Reports : $(SYNTH_DIR)/reports"
	@echo "  Netlist : $(SYNTH_DIR)/netlist"
	@echo ""
	@echo "GLS logs:"
	@echo "  $(GLS_DIR)/logs"
	@echo ""
	@echo "Genus reports:"
	@echo "  Logs    : $(GENUS_OUT)/logs"
	@echo "  Reports : $(GENUS_OUT)/reports"
	@echo "  Netlist : $(GENUS_OUT)/netlist"

all: synth-sky130 sta gls-generic

clean-gls:
	rm -rf $(GLS_DIR)/build $(GLS_DIR)/logs
	rm -f $(ROOT_DIR)/dma_tb.vcd

clean-genus:
	rm -rf $(GENUS_OUT)

clean-synth:
	rm -rf $(SYNTH_DIR)/logs $(SYNTH_DIR)/reports
	rm -f $(SYNTH_DIR)/netlist/*.v $(SYNTH_DIR)/netlist/*.sdf

clean: clean-gls clean-genus clean-synth
