#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GLS_DIR="${ROOT_DIR}/gls"
BUILD_DIR="${GLS_DIR}/build"
LOG_DIR="${GLS_DIR}/logs"

TB_PKG="${ROOT_DIR}/rtl/dma_pkg.sv"
TB_TOP="${ROOT_DIR}/tb/gls/tb_gls.sv"
NETLIST="${ROOT_DIR}/synth/netlist/dma_axi_top_netlist_sky130.v"
SDF="${ROOT_DIR}/synth/netlist/dma_axi_top.sdf"

SIM_OUT="${BUILD_DIR}/dma_gls.out"
WRAPPER="${BUILD_DIR}/gls_wrapper.sv"
COMPILE_LOG="${LOG_DIR}/compile.log"
RUN_LOG="${LOG_DIR}/run.log"

mkdir -p "${BUILD_DIR}" "${LOG_DIR}"
rm -f "${SIM_OUT}" "${WRAPPER}" "${COMPILE_LOG}" "${RUN_LOG}"

fail() {
    echo "[GLS][ERROR] $1" >&2
    exit 1
}

info() {
    echo "[GLS] $1"
}

resolve_pdk_dir() {
    local base=""
    if [[ -n "${SKY130_PDK_ROOT:-}" ]]; then
        base="${SKY130_PDK_ROOT}"
    elif [[ -n "${PDK_ROOT:-}" ]]; then
        base="${PDK_ROOT}"
    else
        fail "Set SKY130_PDK_ROOT or PDK_ROOT before running."
    fi

    local candidates=(
        "${base}/sky130A/libs.ref/sky130_fd_sc_hd/verilog"
        "${base}/libs.ref/sky130_fd_sc_hd/verilog"
        "${base}/sky130A/sky130A/libs.ref/sky130_fd_sc_hd/verilog"
    )

    local d=""
    for d in "${candidates[@]}"; do
        if [[ -d "${d}" ]]; then
            echo "${d}"
            return 0
        fi
    done

    fail "Could not find sky130_fd_sc_hd/verilog under: ${base}"
}

LIB_VERILOG_DIR="$(resolve_pdk_dir)"
PRIMITIVES_V="${LIB_VERILOG_DIR}/primitives.v"
STD_CELL_V="${LIB_VERILOG_DIR}/sky130_fd_sc_hd.v"

[[ -f "${TB_PKG}" ]]       || fail "Missing ${TB_PKG}"
[[ -f "${TB_TOP}" ]]       || fail "Missing ${TB_TOP}"
[[ -f "${NETLIST}" ]]      || fail "Missing ${NETLIST}"
[[ -f "${PRIMITIVES_V}" ]] || fail "Missing ${PRIMITIVES_V}"
[[ -f "${STD_CELL_V}" ]]   || fail "Missing ${STD_CELL_V}"

USE_SDF=0
if [[ -f "${SDF}" ]]; then
    USE_SDF=1
fi

info "Root dir      : ${ROOT_DIR}"
info "TB package    : ${TB_PKG}"
info "TB top        : ${TB_TOP}"
info "Netlist       : ${NETLIST}"
info "SDF           : ${SDF}"
info "PDK verilog   : ${LIB_VERILOG_DIR}"

if [[ "${USE_SDF}" -eq 1 ]]; then
cat > "${WRAPPER}" <<EOF
\`timescale 1ns/1ps
module gls_top;
  dma_tb tb();
  initial begin
    \$display("[GLS] Applying SDF: ${SDF}");
    \$sdf_annotate("${SDF}", tb.dut,,, "MAXIMUM");
  end
endmodule
EOF
else
cat > "${WRAPPER}" <<'EOF'
`timescale 1ns/1ps
module gls_top;
  dma_tb tb();
endmodule
EOF
fi

info "Compiling..."
set +e
iverilog \
  -g2012 \
  -gspecify \
  -Ttyp \
  -DGLS \
  -Wall \
  -o "${SIM_OUT}" \
  -s gls_top \
  "${TB_PKG}" \
  "${TB_TOP}" \
  "${WRAPPER}" \
  "${NETLIST}" \
  "${PRIMITIVES_V}" \
  "${STD_CELL_V}" \
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
