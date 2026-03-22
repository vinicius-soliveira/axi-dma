# DMA AXI Verification

## Overview

This project verifies an AXI-based DMA engine using:

- UVM (constrained-random verification)
- Directed testbench (deterministic scenarios)
- Functional coverage
- Assertions (SVA)
- Regression automation

---

## Requirements

- Cadence Xcelium (`xrun`)
- SystemVerilog + UVM
- Linux environment (bash)

---

## Verification Strategy

The verification approach combines:

- Directed testing for deterministic scenarios
- Constrained-random testing using UVM
- Functional coverage for completeness
- Assertions (SVA) for protocol and control checking
- Regression across multiple seeds

---

## 1. Directed Testbench

### Description

- Simple, deterministic validation
- Internal AXI memory model
- Waveform generation

### Run

```bash
make directed
```

Or manually:

```bash
./scripts/run_directed.sh tb_directed tb_directed 1
```

---

## 2. UVM Environment

### Components

- AXI-Lite agent (driver + monitor)
- Virtual sequencer
- Scoreboard (data checking)
- Coverage collector
- Error injection support

---

## Available Tests

| Test | Description |
|------|------------|
| `dma_smoke_test` | Basic functionality |
| `dma_random_test` | Constrained-random |
| `dma_error_injection_test` | Error handling |
| `dma_backpressure_test` | Backpressure scenarios |
| `dma_corner_cases_test` | Edge cases |
| `dma_reset_mid_transfer_test` | Reset robustness |

---

## Run UVM Tests

### Using Makefile (recommended)

```bash
make smoke
make random
make regress
```

### Manual execution

```bash
./scripts/run.sh dma_random_test "1 2 3 4 5" UVM_LOW
```

---

## 3. Regression

Runs multiple seeds and aggregates results.

```bash
make regress
```

---

## 4. Functional Coverage

### Implementation

Located at:

```
tb/uvm/coverage/
```

### Metrics

- Transfer size (`len_bytes`)
- Burst configuration (`max_beats`)
- Number of bursts
- Transfer outcome (DONE / ERROR)
- Cross coverage:
  - size × burst
  - burst × outcome

---

## Coverage Flow

Coverage is enabled automatically by `run.sh`.

Database location:

```
sim/coverage/<test>/*.ucd
```

---

## 5. Assertions (SVA)

### Implementation

```
tb/assertions/
tb/binds/
```

### Coverage

Assertions check:

- AXI VALID/READY protocol
- DMA control flow (start → done/error)
- Status correctness
- Read/write channel behavior

---

## Assertion Results

Extracted from logs:

```
Total Assertions
Failing Assertions
Unchecked Assertions
```

Available in:

```
sim/regression/<test>/assertions_report.txt
```

---

## Simulation Outputs

```
sim/
├── regression/
├── coverage/
└── logs/
```

