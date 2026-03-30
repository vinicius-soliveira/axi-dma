# Scripts README — axi_dma

## Overview

This directory contains all automation scripts used in the `axi_dma` project.

These scripts support:
- RTL simulation
- logic synthesis (Yosys)
- static timing analysis (OpenSTA)
- gate-level simulation (GLS)
- Cadence Genus synthesis flow

---

## Script List

### Simulation Scripts

#### `run.sh`
Runs the main RTL simulation flow.

- Compiles RTL + testbench
- Executes simulation
- Generates waveform (VCD)

---

#### `run_directed.sh`
Runs directed testbench simulations.

- Focused tests
- Deterministic scenarios
- Useful for debugging

---

###  Synthesis Scripts (Yosys)

#### `synth.ys`
Generic synthesis script.

- RTL elaboration
- Optimization
- Generic netlist generation

---

#### `synth_sky130.ys`
Technology-mapped synthesis for SKY130.

- Maps RTL to SKY130 standard cells
- Generates netlist compatible with PDK

---

###  Timing Analysis

#### `sta.tcl`
Static Timing Analysis script for OpenSTA.

- Loads netlist
- Loads liberty file
- Applies SDC constraints
- Generates timing reports

---

### ⚡ Gate-Level Simulation (GLS)

#### `run_gls_generic.sh`
Runs GLS using generic netlist.

- Uses synthesized netlist (no PDK dependency)
- Faster and more stable for debugging

---

#### `run_gls.sh`
Runs GLS using SKY130-mapped netlist.

- Uses SKY130 standard-cell models
- Closer to real hardware
- May expose X-propagation issues

---

### Cadence Genus Scripts

#### `genus.tcl`
Generic Genus synthesis script.

- Reads RTL
- Applies constraints
- Performs synthesis
- Generates netlist, reports, and SDF

---

#### `genus_sky130_specific.tcl`
SKY130-specific Genus script.

- Automatically detects SKY130 liberty
- Supports multiple environment variables:
  - `LIB_FILES`
  - `SKY130_LIB`
  - `SKY130_PDK_ROOT`
  - `PDK_ROOT`

---

#### `run_genus.sh`
Wrapper script for Genus.

- Sets environment variables
- Resolves library paths
- Executes Genus in batch mode
- Logs output

---

#### `run_genus_sky130_specific.sh`
Variant of Genus runner optimized for SKY130 setups.

- Auto-detects SKY130 installation
- Simplifies execution

---

###  File List

#### `filelist.f`
List of RTL source files.

- Used for compilation flows
- Ensures consistent file ordering

---

##  Typical Workflows

###  RTL Simulation

```bash
./scripts/run.sh
```

or:

```bash
./scripts/run_directed.sh
```

---

###  Synthesis + STA

```bash
yosys -s scripts/synth_sky130.ys
sta scripts/sta.tcl
```

---

### GLS (Recommended Debug Flow)

```bash
./scripts/run_gls_generic.sh
```

---

### GLS with SKY130

```bash
./scripts/run_gls.sh
```

---

### Genus Flow

```bash
./scripts/run_genus.sh
```

or via Makefile:

```bash
make genus
```

---

##  Notes

- Prefer `run_gls_generic.sh` for debugging:
  - Faster
  - More stable
- Use SKY130 GLS for:
  - Final validation
  - X-propagation analysis
- Genus scripts provide:
  - Industrial-grade synthesis
  - Better PPA visibility

---

## Requirements

- Yosys
- OpenSTA
- Icarus Verilog
- Cadence Xcelium
- Cadence Genus
- SKY130 PDK (for mapped synthesis)

---

## Summary

This scripts directory centralizes all automation required for:

- simulation
- synthesis
- timing analysis
- GLS validation

It enables a reproducible and scalable front-end ASIC flow for the `axi_dma` project.
