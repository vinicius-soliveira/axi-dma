# AXI DMA Controller

## Overview

This repository implements a simplified **AXI-based Memory-to-Memory (MM2MM) DMA controller** in SystemVerilog.

The design supports burst-based transfers between memory-mapped regions using AXI4 master interfaces and is intended for **learning and architectural exploration**.

---

## Scope

### Supported

- Memory-to-Memory transfers (MM2MM)
- Single descriptor
- Single outstanding transaction
- Incrementing bursts (INCR)
- Configurable burst length
- AXI-Lite control interface (CSR)

### Not Supported

- Scatter-gather
- Multi-channel DMA
- AXI-Stream
- Out-of-order execution
- Unaligned transfers

---

## Architecture

Main modules:

- `dma_axi_top` — top-level integration
- `dma_fsm` — control state machine
- `dma_axi_master_rd` — AXI read engine
- `dma_axi_master_wr` — AXI write engine
- `dma_fifo` — read/write decoupling
- `dma_csr` — configuration and status
- `dma_pkg` — shared definitions

---

## Getting Started

### Run UVM tests (recommended)

```bash
make smoke
make random
make regress
```

### Run directed testbench

```bash
make directed
```

### Manual execution

```bash
./scripts/run.sh dma_random_test "1 2 3 4 5" UVM_LOW
```

---

## Simulation Outputs

All simulation artifacts are stored under:

```
sim/
├── regression/
├── coverage/
└── logs/
```

### Logs

```
sim/logs/<test>/seed_X/run.log
```

### Coverage database

```
sim/coverage/<test>/*.ucd
```

### Reports

```
sim/regression/<test>/
├── regression_summary.txt
├── coverage_report.txt
└── assertions_report.txt
```

---

## Verification

The verification environment includes:

- UVM-based testbench
- Directed testbench
- Functional coverage
- Assertions (SVA)
- Regression infrastructure

See `tb/README.md` for details.

---

## Synthesis

The design can be synthesized using **Yosys** for RTL validation and early area/timing estimation.

### Requirements

- Yosys (latest recommended)
- ABC (usually bundled with Yosys)

### Running synthesis

```bash
yosys -s scripts/synth.ys
```

### Synthesis flow

The synthesis script performs:

- RTL elaboration
- SystemVerilog to generic netlist lowering
- Technology mapping using ABC
- Optimization passes
- Optional reporting (area/cell usage)

### Inputs

- RTL sources under `rtl/`
- Synthesis script: `scripts/synth.ys`

### Outputs

```
synth/
├── netlist.v
├── reports/
└── logs/
```

## Author

Vinícius Oliveira
Electronic Engineer | Hardware & Firmware Development
