# AXI DMA Controller

## Overview

This repository implements a simplified AXI-based Memory-to-Memory (MM2MM) DMA controller in SystemVerilog.

The design performs burst-based data transfers between memory-mapped regions using AXI4 master interfaces and is intended for:

- architectural exploration  
- front-end ASIC design practice  
- verification methodology development  

The project includes RTL, verification environment, synthesis flow, timing analysis, and gate-level simulation.

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

- dma_axi_top — top-level integration  
- dma_fsm — control state machine  
- dma_axi_master_rd — AXI read engine  
- dma_axi_master_wr — AXI write engine  
- dma_fifo — read/write decoupling  
- dma_csr — configuration and status registers  
- dma_pkg — shared definitions  

### Data Flow

1. CPU configures DMA via AXI-Lite  
2. FSM starts transfer  
3. Read engine fetches data from source  
4. FIFO buffers data  
5. Write engine sends data to destination  
6. FSM signals completion  

---

## Project Structure

axi_dma/
├── rtl/
├── tb/
├── scripts/
├── synth/
├── gls/
├── sim/
└── Makefile

---

## Getting Started

### Run UVM tests

make smoke  
make random  
make regress  

### Run directed testbench

make directed  

### Manual execution

./scripts/run.sh dma_random_test "1 2 3 4 5" UVM_LOW  

---

## Simulation Outputs

sim/
├── regression/
├── coverage/
└── logs/

---

## Verification

- UVM testbench  
- Directed tests  
- Functional coverage  
- SystemVerilog Assertions  
- Regression flow  

---

## Synthesis Flow

### Yosys

make synth-sky130  

---

## Static Timing Analysis

make sta  

---

## Gate-Level Simulation

make gls-generic  
make gls-sky130  

---

## Cadence Genus Flow

make genus  

---

## Build System

make help  

---

## Known Limitations

- Single-channel DMA  

---

## Future Work

- Extend features and verification  

---

## Author

Vinícius Oliveira
