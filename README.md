# AXI DMA Controller

> Simplified AXI-based Memory-to-Memory (MM2MM) DMA controller in SystemVerilog  
> Focused on ASIC front-end design, verification, and synthesis flow

---

## Overview

This project implements a burst-based DMA controller capable of transferring data between memory-mapped regions using AXI4 master interfaces.

It is designed for:

- Architectural exploration  
- Front-end ASIC design practice  
- Verification methodology development  

The repository includes:

- RTL design  
- UVM verification environment  
- Synthesis (Yosys + Sky130)  
- Static timing analysis (OpenSTA)  
- Gate-level simulation (GLS)  

---

## Features

### Supported

- MM2MM transfers  
- Single descriptor  
- Single outstanding transaction  
- Incrementing bursts (INCR)  
- Configurable burst length  
- AXI-Lite CSR interface  

### Not Supported

- Scatter-gather  
- Multi-channel DMA  
- AXI-Stream  
- Out-of-order execution  
- Unaligned transfers  

---

## Architecture

### Main Modules

| Module | Description |
|------|------------|
| `dma_axi_top` | Top-level integration |
| `dma_fsm` | Control state machine |
| `dma_axi_master_rd` | AXI read engine |
| `dma_axi_master_wr` | AXI write engine |
| `dma_fifo` | Read/write decoupling |
| `dma_csr` | Configuration and status registers |
| `dma_pkg` | Shared definitions |

---

---

## Project Structure

```text
axi_dma/
├── rtl/        # RTL design
├── tb/         # Testbenches (UVM + directed)
├── scripts/    # Simulation and synthesis scripts
├── synth/      # Netlists, reports, STA
├── gls/        # Gate-level simulation
├── sim/        # Simulation outputs
└── Makefile
```

---

## Getting Started

### Run UVM Tests

```bash
make smoke
make random
make regress
```

### Run Directed Testbench

```bash
make directed
```

### Manual Execution

```bash
./scripts/run.sh dma_random_test "1 2 3 4 5" UVM_LOW
```

---

## Simulation Outputs

```text
sim/
├── regression/
├── coverage/
└── logs/
```

---

## Verification

- UVM testbench  
- Directed tests  
- Functional coverage  
- SystemVerilog Assertions (SVA)  
- Regression flow  

---

## Synthesis Flow

### Yosys + Sky130

```bash
make synth-sky130
```

---

## Static Timing Analysis

```bash
make sta
```

---

## Gate-Level Simulation

```bash
make gls-generic
make gls-sky130
```

---

## Cadence Genus Flow (Optional)

```bash
make genus
```

---

## Build System

```bash
make help
```

---

## Known Limitations

- Single-channel DMA  
- No support for multiple outstanding transactions  
- FIFO implemented using flip-flops  

---

## Future Work

- Multi-channel support  
- Scatter-gather DMA  
- AXI performance optimizations  
- Memory macro integration for FIFO  

---

## Author

**Vinícius Oliveira**
