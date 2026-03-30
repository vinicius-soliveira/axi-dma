#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GLS_DIR="${ROOT_DIR}/gls"
BUILD_DIR="${GLS_DIR}/build"
LOG_DIR="${GLS_DIR}/logs"

TB_PKG="${ROOT_DIR}/rtl/dma_pkg.sv"
TB_TOP="${ROOT_DIR}/tb/gls/tb_gls_generic.sv"
NETLIST="${ROOT_DIR}/synth/netlist/dma_axi_top_netlist.v"

SIM_OUT="${BUILD_DIR}/dma_gls_generic.out"
COMPILE_LOG="${LOG_DIR}/compile_generic.log"
RUN_LOG="${LOG_DIR}/run_generic.log"

mkdir -p "${BUILD_DIR}" "${LOG_DIR}"
rm -f "${SIM_OUT}" "${COMPILE_LOG}" "${RUN_LOG}"

fail() {
    echo "[GLS-GEN][ERROR] $1" >&2
    exit 1
}

info() {
    echo "[GLS-GEN] $1"
}

[[ -f "${TB_PKG}" ]]  || fail "Missing ${TB_PKG}"
[[ -f "${TB_TOP}" ]]  || fail "Missing ${TB_TOP}"
[[ -f "${NETLIST}" ]] || fail "Missing ${NETLIST}"

info "Root dir   : ${ROOT_DIR}"
info "TB package : ${TB_PKG}"
info "TB top     : ${TB_TOP}"
info "Netlist    : ${NETLIST}"

info "Compiling..."
set +e
iverilog \
  -g2012 \
  -Wall \
  -DGLS \
  -o "${SIM_OUT}" \
  -s dma_tb \
  "${TB_PKG}" \
  "${TB_TOP}" \
  "${NETLIST}" \
  2>&1 | tee "${COMPILE_LOG}"
IVERILOG_STATUS=${PIPESTATUS[0]}
set -e

info "iverilog exit code: ${IVERILOG_STATUS}"

if [[ ! -f "${SIM_OUT}" ]]; then
    fail "Compilation did not produce output binary. Check ${COMPILE_LOG}"
fi

info "Running..."
set +e
vvp "${SIM_OUT}" 2>&1 | tee "${RUN_LOG}"
VVP_STATUS=${PIPESTATUS[0]}
set -e

info "vvp exit code: ${VVP_STATUS}"

if [[ "${VVP_STATUS}" -ne 0 ]]; then
    fail "Simulation failed. Check ${RUN_LOG}"
fi

info "Done."
info "Compile log : ${COMPILE_LOG}"
info "Run log     : ${RUN_LOG}"
info "Executable  : ${SIM_OUT}"
