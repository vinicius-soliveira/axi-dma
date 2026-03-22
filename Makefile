SHELL := /bin/bash

TEST ?= dma_random_test
SEEDS ?= 1 2 3 4 5
VERBOSITY ?= UVM_LOW

DIRECTED_TEST ?= tb_directed
DIRECTED_TOP ?= tb_directed
DIRECTED_SEED ?= 1

.PHONY: help run smoke random corner backpressure readerr resetmid errorinj factory regress directed clean clean-sim tree

help:
	@echo "Available targets:"
	@echo
	@echo "  make run TEST=<test> SEEDS=\"1 2 3\" VERBOSITY=UVM_LOW"
	@echo "  make smoke"
	@echo "  make random"
	@echo "  make corner"
	@echo "  make backpressure"
	@echo "  make readerr"
	@echo "  make resetmid"
	@echo "  make errorinj"
	@echo "  make factory"
	@echo "  make regress"
	@echo "  make directed"
	@echo "  make clean"
	@echo "  make clean-sim"
	@echo "  make tree"
	@echo
	@echo "Directed options:"
	@echo "  make directed DIRECTED_TEST=tb_directed DIRECTED_TOP=tb_directed DIRECTED_SEED=1"

run:
	bash scripts/run.sh "$(TEST)" "$(SEEDS)" "$(VERBOSITY)"

smoke:
	$(MAKE) run TEST=dma_smoke_test SEEDS="1" VERBOSITY=UVM_LOW

random:
	$(MAKE) run TEST=dma_random_test SEEDS="1 2 3 4 5" VERBOSITY=UVM_LOW

corner:
	$(MAKE) run TEST=dma_corner_cases_test SEEDS="1" VERBOSITY=UVM_LOW

backpressure:
	$(MAKE) run TEST=dma_backpressure_test SEEDS="1" VERBOSITY=UVM_LOW

readerr:
	$(MAKE) run TEST=dma_read_error_injection_test SEEDS="1" VERBOSITY=UVM_LOW

resetmid:
	$(MAKE) run TEST=dma_reset_mid_transfer_test SEEDS="1" VERBOSITY=UVM_LOW

errorinj:
	$(MAKE) run TEST=dma_error_injection_test SEEDS="1" VERBOSITY=UVM_LOW

factory:
	$(MAKE) run TEST=dma_factory_override_test SEEDS="1" VERBOSITY=UVM_LOW

regress:
	$(MAKE) run TEST=dma_random_test SEEDS="1 2 3 4 5" VERBOSITY=UVM_LOW

directed:
	bash scripts/run_directed.sh "$(DIRECTED_TEST)" "$(DIRECTED_TOP)" "$(DIRECTED_SEED)"

clean:
	rm -rf xcelium.d waves.shm *.history

clean-sim:
	rm -rf sim

tree:
	tree .
