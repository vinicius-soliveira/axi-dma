# DMA AXI RTL Architecture

## Overview

This project implements a configurable **DMA (Direct Memory Access) engine** with AXI-based interfaces for memory transactions and a CSR interface for software control.

The design is fully described at RTL level using SystemVerilog and organized in a modular architecture to separate control, data path, and protocol handling.

---

## Top-Level Architecture

The top-level module (`dma_axi_top`) integrates the following main components:

* Control/Status Registers (CSR)
* Read AXI Master
* Write AXI Master
* Internal FIFO buffer
* Central FSM controller

The architecture follows a **command-driven DMA model**, where software configures transfer parameters via CSR and triggers execution.

---

## Main Modules

### 1. CSR (Control and Status Registers)

**Module:** `dma_csr.sv`

Responsible for:

* Receiving configuration from software
* Storing DMA parameters:

  * Source address
  * Destination address
  * Transfer length
  * Control signals
* Exposing status:

  * Busy
  * Done
  * Error

Acts as the **software-to-hardware interface**.

---

### 2. Central FSM

**Module:** `dma_fsm.sv`

Implements the control logic of the DMA engine.

#### Responsibilities:

* Sequencing the DMA operation
* Coordinating read and write channels
* Managing start/done handshake
* Controlling FIFO flow

#### Typical States:

* `IDLE` – waiting start signal
* `READ` – issuing AXI read transactions
* `WRITE` – issuing AXI write transactions
* `DONE` – signaling completion

The FSM ensures proper ordering and synchronization between modules.

---

### 3. AXI Read Master

**Module:** `dma_axi_master_rd.sv`

Handles AXI read transactions.

#### Responsibilities:

* Generating AXI read address channel (AR)
* Receiving read data (R channel)
* Forwarding data into FIFO

#### Features:

* Burst-based transfers
* Handshake-compliant (VALID/READY)
* Controlled by FSM

---

### 4. AXI Write Master

**Module:** `dma_axi_master_wr.sv`

Handles AXI write transactions.

#### Responsibilities:

* Generating AXI write address channel (AW)
* Sending write data (W channel)
* Handling write responses (B channel)

#### Features:

* Consumes data from FIFO
* Supports burst writes
* Backpressure-aware via FIFO status

---

### 5. FIFO Buffer

**Module:** `dma_fifo.sv`

Acts as a **data decoupling buffer** between read and write paths.

#### Responsibilities:

* Temporary storage of data read from memory
* Fix latency differences between AXI read and write channels

#### Key Properties:

* Prevents read/write coupling
* Supports flow control:

  * Full → stalls read
  * Empty → stalls write

---

### 6. Package Definitions

**Module:** `dma_pkg.sv`

Contains:

* Type definitions
* Constants
* FSM states

---

## Data Flow

1. Software programs CSR with:

   * Source address
   * Destination address
   * Transfer size

2. FSM transitions from `IDLE` to active state

3. Read Master:

   * Fetches data from source memory
   * Pushes into FIFO

4. Write Master:

   * Pulls data from FIFO
   * Writes to destination memory

5. FSM monitors progress:

   * Completes transfer
   * Updates status (DONE)

---

## Control Flow

* **Start signal** triggers FSM execution
* FSM orchestrates:

  * AXI read requests
  * FIFO write/read enables
  * AXI write requests
* Completion is signaled back via CSR

---

## Scalability

The architecture allows future extensions such as:

* Multiple outstanding transactions
* Scatter-gather support
* Interrupt generation
* Error handling enhancements

---
