#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GENUS_TCL="${ROOT_DIR}/scripts/genus.tcl"
OUT_DIR="${OUT_DIR:-${ROOT_DIR}/synth/genus}"
TOP_MODULE="${TOP_MODULE:-dma_axi_top}"
RTL_DIR="${RTL_DIR:-${ROOT_DIR}/rtl}"
CONSTRAINTS_FILE="${CONSTRAINTS_FILE:-${ROOT_DIR}/synth/constraints/dma_axi_top.sdc}"

detect_sky130_lib() {
  if [[ -n "${LIB_FILES:-}" ]]; then
    echo "${LIB_FILES}"
    return 0
  fi

  if [[ -n "${SKY130_LIB:-}" ]]; then
    echo "${SKY130_LIB}"
    return 0
  fi

  local candidates=()

  if [[ -n "${SKY130_PDK_ROOT:-}" ]]; then
    candidates+=(
      "${SKY130_PDK_ROOT}/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
      "${SKY130_PDK_ROOT}/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
    )
  fi

  if [[ -n "${PDK_ROOT:-}" ]]; then
    candidates+=(
      "${PDK_ROOT}/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
      "${PDK_ROOT}/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
    )
  fi

  local c
  for c in "${candidates[@]}"; do
    if [[ -f "${c}" ]]; then
      echo "${c}"
      return 0
    fi
  done

  return 1
}

LIB_FILES_RESOLVED="$(detect_sky130_lib || true)"
if [[ -z "${LIB_FILES_RESOLVED}" ]]; then
  echo "[GENUS][ERROR] Could not resolve SKY130 liberty."
  echo "Set one of:"
  echo "  export LIB_FILES=/path/to/sky130_fd_sc_hd__tt_025C_1v80.lib"
  echo "  export SKY130_LIB=/path/to/sky130_fd_sc_hd__tt_025C_1v80.lib"
  echo "  export SKY130_PDK_ROOT=/home/vinicius.silva/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
  echo "  export PDK_ROOT=/path/to/pdk"
  exit 2
fi

mkdir -p "${OUT_DIR}/logs"

echo "[GENUS] ROOT_DIR         = ${ROOT_DIR}"
echo "[GENUS] TOP_MODULE       = ${TOP_MODULE}"
echo "[GENUS] RTL_DIR          = ${RTL_DIR}"
echo "[GENUS] CONSTRAINTS_FILE = ${CONSTRAINTS_FILE}"
echo "[GENUS] OUT_DIR          = ${OUT_DIR}"
echo "[GENUS] LIB_FILES        = ${LIB_FILES_RESOLVED}"

export TOP_MODULE RTL_DIR CONSTRAINTS_FILE OUT_DIR
export LIB_FILES="${LIB_FILES_RESOLVED}"

genus -no_gui -files "${GENUS_TCL}" | tee "${OUT_DIR}/logs/genus.log"
