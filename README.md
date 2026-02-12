# AXI DMA

## Overview

This repository contains a parameterizable AXI-based DMA (Direct Memory Access) controller written in SystemVerilog.  

---

## Key Features

- AXI4 Read and Write Master Interfaces
- Parameterizable Data Width and Address Width
- Configurable FIFO Depth
- CSR-Based Control Interface
- Transfer Control FSM
- Burst Transfer Support
---

## Architecture

The DMA is composed of the following main blocks:

- **dma_axi_master_read**

Implements AXI read master logic for generating read bursts and receiving data from memory.

- **dma_axi_master_wr**

Implements AXI write master logic for sending data bursts to memory and handling write responses.

- **dma_fsm**

Main DMA control finite state machine responsible for transfer sequencing and datapath coordination.

 - **dma_csr**

Control and Status Register interface providing software access to DMA configuration and status.

- **dma_fifo**

Parameterizable FIFO buffer used to decouple AXI timing from internal DMA datapath timing.

- **dma_pkg**

Global package containing shared parameters, typedefs, enumerations, and constants used across the DMA subsystem.

 - **dma_axi_top**

Top-level integration module connecting all DMA blocks and exposing system interfaces.





