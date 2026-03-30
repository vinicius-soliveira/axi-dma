# Unified Makefile for `axi_dma`

## Overview

This Makefile provides a unified command-line flow for the `axi_dma` project, covering:

- generic synthesis with Yosys
- SKY130-mapped synthesis with Yosys
- static timing analysis with OpenSTA
- gate-level simulation (generic and SKY130 flows)
- Cadence Genus synthesis flow
- cleanup and report navigation

It is intended to simplify task execution and keep the project flow reproducible.

---

## File Placement

Save this Makefile at the project root:

```text
axi_dma/Makefile
```

The Makefile expects the following project structure:

```text
axi_dma/
├── rtl/
├── scripts/
│   ├── synth.ys
│   ├── synth_sky130.ys
│   ├── sta.tcl
│   ├── run_gls.sh
│   ├── run_gls_generic.sh
│   ├── genus.tcl
│   └── run_genus.sh
├── synth/
│   ├── constraints/
│   │   └── dma_axi_top.sdc
│   └── netlist/
├── tb/
└── gls/
```

---

## Available Targets

### Environment and setup

```bash
make env
```

Prints the main paths and variables used by the flow.

```bash
make dirs
```

Creates the required output directories.

---

### Open-source synthesis flow

```bash
make synth
```

Runs generic synthesis using `scripts/synth.ys`.

```bash
make synth-sky130
```

Runs SKY130-mapped synthesis using `scripts/synth_sky130.ys`.

```bash
make sta
```

Runs static timing analysis using `scripts/sta.tcl`.

---

### Gate-Level Simulation

```bash
make gls-generic
```

Runs GLS using the generic netlist and `scripts/run_gls_generic.sh`.

```bash
make gls-sky130
```

Runs GLS using the SKY130-mapped netlist and `scripts/run_gls.sh`.

```bash
make gls
```

Alias for `make gls-generic`.

---

### Cadence Genus flow

```bash
make genus
```

Runs the Cadence Genus flow using:

- `scripts/genus.tcl`
- `scripts/run_genus.sh`

The Makefile automatically passes:

- top module
- RTL directory
- SDC file
- output directory
- SKY130 liberty path

---

### Reports and cleanup

```bash
make reports
```

Shows the locations of logs, reports, and generated netlists.

```bash
make clean
```

Removes generated artifacts from synthesis, GLS, and Genus.

---

## Default SKY130 Configuration

The Makefile includes a default SKY130 root path:

```make
SKY130_PDK_ROOT ?= /home/vinicius.silva/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af
```

and derives the default liberty file from it:

```make
LIB_FILES ?= $(SKY130_PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
```

If your installation path is different, override it when invoking `make`:

```bash
make genus SKY130_PDK_ROOT=/your/path/to/sky130
```

or:

```bash
make genus LIB_FILES=/your/path/to/sky130_fd_sc_hd__tt_025C_1v80.lib
```

---

## Typical Usage

### Open-source flow

```bash
make synth-sky130
make sta
make gls-generic
```

### Cadence Genus flow

```bash
make genus
```

### Inspect environment

```bash
make env
```

---

## Notes

- `make all` runs:
  - `make synth-sky130`
  - `make sta`
  - `make gls-generic`

- The Makefile does not generate the project scripts itself. It expects the required files to already exist under `scripts/`.

- For the Genus target to work, the `genus` executable must be available in your environment.

---

## Summary

This Makefile centralizes the main front-end ASIC flow tasks for the `axi_dma` project and makes it easier to run synthesis, timing analysis, GLS, and Genus from one place.
