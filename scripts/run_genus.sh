#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GENUS_TCL="${ROOT_DIR}/scripts/genus.tcl"
OUT_DIR="${OUT_DIR:-${ROOT_DIR}/synth/genus}"
TOP_MODULE="${TOP_MODULE:-dma_axi_top}"
RTL_DIR="${RTL_DIR:-${ROOT_DIR}/rtl}"
CONSTRAINTS_FILE="${CONSTRAINTS_FILE:-${ROOT_DIR}/synth/constraints/dma_axi_top.sdc}"

if [[ -z "${LIB_FILES:-}" ]]; then
  echo "[GENUS][ERROR] LIB_FILES is not set."
  echo "Example:"
  echo "  export LIB_FILES=\"/path/to/sky130_fd_sc_hd__tt_025C_1v80.lib\""
  exit 2
fi

mkdir -p "${OUT_DIR}/logs"

echo "[GENUS] ROOT_DIR         = ${ROOT_DIR}"
echo "[GENUS] TOP_MODULE       = ${TOP_MODULE}"
echo "[GENUS] RTL_DIR          = ${RTL_DIR}"
echo "[GENUS] CONSTRAINTS_FILE = ${CONSTRAINTS_FILE}"
echo "[GENUS] OUT_DIR          = ${OUT_DIR}"
echo "[GENUS] LIB_FILES        = ${LIB_FILES}"

export TOP_MODULE RTL_DIR CONSTRAINTS_FILE OUT_DIR

genus -no_gui -files "${GENUS_TCL}" | tee "${OUT_DIR}/logs/genus.log"
