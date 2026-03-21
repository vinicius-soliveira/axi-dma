# AXI DMA Controller

##  Overview

This repository contains a simplified, parameterizable AXI-based DMA (Direct Memory Access) controller implemented in **SystemVerilog**.

The design implements a **memory-to-memory (MM2MM) DMA engine**, capable of transferring data between two memory-mapped regions using AXI4 master interfaces.

This is a single-channel, single-descriptor DMA, intended for learning, experimentation, and architectural exploration — not a full production-grade DMA.

---

## Scope of Implementation

###  DMA Type

The following DMA model is implemented:

* **Memory-to-Memory (MM2MM)** transfers
* **Single transfer descriptor**
* **Single outstanding transaction per channel**
* **Burst-based transfer engine**

Not supported:

*  Scatter-gather DMA
*  Linked descriptors
*  Multi-channel DMA
*  Peripheral streaming interfaces (AXI-Stream)
---

###  AXI Protocol Coverage

This design implements a **subset of the AXI4 protocol**, focused on basic memory transactions.

#### Implemented (AXI4 Full — simplified usage):

*  Read Address Channel (`AR*`)
*  Read Data Channel (`R*`)
*  Write Address Channel (`AW*`)
*  Write Data Channel (`W*`)
*  Write Response Channel (`B*`)

Supported features:

*  Incrementing bursts (`INCR`)
*  Configurable burst length (up to 256 beats)
*  Single outstanding transaction per channel
*  Basic backpressure handling (`READY/VALID`)

---

#### Not Implemented:

*  Multiple outstanding transactions (no ID tracking)
*  Out-of-order completion
*  Exclusive accesses
*  Lock transactions
*  QoS / Region / Cache advanced usage
*  Narrow bursts / unaligned bursts (alignment required)
*  AXI4-Stream interface

---

## Key Features

* AXI4 Read Master Interface
* AXI4 Write Master Interface
* AXI-Lite Control Interface (CSR)
* Parameterizable data width, address width, and FIFO depth
* Burst-based transfers with configurable maximum burst length
* FIFO buffering between read and write paths
* **Pipelined read/write operation (performance optimized)**
* Error detection and reporting
* Interrupt support

---

## Architecture

The DMA is composed of the following main modules:

### `dma_axi_top`

Top-level integration module that connects all submodules and exposes system interfaces.

### `dma_fsm`

Core control finite state machine responsible for:

* Transfer sequencing
* Burst management
* Pipeline control (read/write overlap)
* Error handling

### `dma_axi_master_rd`

Implements AXI read transactions:

* Issues read bursts
* Receives data from memory
* Pushes data into FIFO

###  `dma_axi_master_wr`

Implements AXI write transactions:

* Issues write bursts
* Consumes data from FIFO
* Handles write responses

### `dma_fifo`

Parameterizable FIFO used to decouple:

* AXI read timing
* AXI write timing

### `dma_csr`

Control and Status Register block:

* Configures transfers
* Provides status feedback
* Generates interrupts

###  `dma_pkg`

Shared package containing:

* Parameters
* Type definitions
* Enumerations (FSM states, error codes)

---


## Pipelining Strategy

The FSM introduces a pipeline stage:

* `ST_PIPE_WR_ADDR`:
  Issues write address while read is still in progress

Pipeline entry conditions:

* FIFO contains enough data for the burst
* Write master is idle

This prevents:

* FIFO underflow
* AXI write stalls

---

## Parameters

| Parameter    | Description             |
| ------------ | ----------------------- |
| `ADDR_WIDTH` | Address bus width       |
| `DATA_WIDTH` | AXI data width          |
| `FIFO_DEPTH` | Depth of internal FIFO  |
| `max_beats`  | Maximum beats per burst |

---

