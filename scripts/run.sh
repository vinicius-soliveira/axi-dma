#!/usr/bin/env bash

set -euo pipefail

# =======================================
# User config
# =======================================
TEST="${1:-dma_corner_cases_test}"
SEEDS="${2:-1 2 3 4 5}"
VERBOSITY="${3:-UVM_LOW}"

TOP="tb_top"
FILELIST="scripts/filelist.f"

SIM_ROOT="sim"
REG_ROOT="${SIM_ROOT}/regression"
COV_ROOT="${SIM_ROOT}/coverage"
LOG_ROOT="${SIM_ROOT}/logs"

REG_OUT="${REG_ROOT}/${TEST}"
COV_DIR="${COV_ROOT}/${TEST}"
LOG_DIR="${LOG_ROOT}/${TEST}"
TCL_FILE="${REG_OUT}/xrun_post.tcl"

read -r -a SEED_LIST <<< "$SEEDS"

# =======================================
# Helpers
# =======================================
extract_assert_triplet() {
  local logfile="$1"
  local line
  line="$(grep -Ei "Total Assertions *=|Failing Assertions *=|Unchecked Assertions *=" "$logfile" | tail -n 1 || true)"

  if [[ -n "$line" ]]; then
    local total fail unchecked
    total="$(echo "$line" | sed -n 's/.*Total Assertions *= *\([0-9][0-9]*\).*/\1/p')"
    fail="$(echo "$line" | sed -n 's/.*Failing Assertions *= *\([0-9][0-9]*\).*/\1/p')"
    unchecked="$(echo "$line" | sed -n 's/.*Unchecked Assertions *= *\([0-9][0-9]*\).*/\1/p')"
    echo "${total:-0} ${fail:-0} ${unchecked:-0}"
  else
    echo "0 0 0"
  fi
}

has_uvm_failures() {
  local logfile="$1"
  grep -Eqi "UVM_ERROR[[:space:]]*:[[:space:]]*[1-9]|UVM_FATAL[[:space:]]*:[[:space:]]*[1-9]" "$logfile"
}

has_assert_failures() {
  local logfile="$1"
  grep -Eqi 'assert(ion)? .*fail|assertion failed|\*E,AS|\[SVA\].*fail|\$error' "$logfile"
}

# =======================================
# Banner
# =======================================
echo "======================================="
echo " Running test: $TEST"
echo " Seeds:        ${SEED_LIST[*]}"
echo " Verbosity:    $VERBOSITY"
echo " Regression:   $REG_OUT"
echo " Coverage dir: $COV_DIR"
echo " Logs dir:     $LOG_DIR"
echo "======================================="

rm -rf "$REG_OUT" "$COV_DIR" "$LOG_DIR"
mkdir -p "$REG_OUT" "$COV_DIR" "$LOG_DIR"

# =======================================
# TCL post-run commands
# =======================================
cat > "$TCL_FILE" <<'EOF'
run
assertion -summary
coverage -dump cov_dump
exit
EOF

# =======================================
# Compile
# =======================================
echo "[RUN] Compiling..."

xrun \
  -64bit \
  -sv \
  -uvm \
  -assert \
  -coverage all \
  -covoverwrite \
  -covworkdir "$COV_DIR" \
  -f "$FILELIST" \
  -top "$TOP" \
  -access +rwc \
  -timescale 1ns/1ps \
  -l "$LOG_DIR/compile.log" \
  -elaborate

cp "$LOG_DIR/compile.log" "$REG_OUT/compile.log"

echo "[RUN] Compile done."

# =======================================
# Instrumentation report
# =======================================
{
  echo "======================================="
  echo " Build / instrumentation report"
  echo "======================================="
  echo
  echo "[Coverage instrumentation]"
  grep -Ei "Enabling instrumentation for coverage types|coverage types|FSM extracted|Covergroup Instances|coverage setup:" "$REG_OUT/compile.log" \
    || echo "No explicit coverage instrumentation lines found in compile.log"
  echo
  echo "[Assertion instrumentation]"
  grep -Ei "Assertions:|assertions enabled|assertion" "$REG_OUT/compile.log" \
    || echo "No explicit assertion instrumentation lines found in compile.log"
} > "$REG_OUT/build_report.txt"

PASS_COUNT=0
FAIL_COUNT=0
FAILED_SEEDS=""

TOTAL_ASSERT_SUM=0
TOTAL_FAIL_ASSERT_SUM=0
TOTAL_UNCHECKED_SUM=0

FUNC_COV_EVENTS_FILE="$REG_OUT/.func_cov_events.tmp"
ASSERT_EVENTS_FILE="$REG_OUT/.assert_events.tmp"
: > "$FUNC_COV_EVENTS_FILE"
: > "$ASSERT_EVENTS_FILE"

# =======================================
# Regression loop
# =======================================
for SEED in "${SEED_LIST[@]}"; do
  OUT="${REG_OUT}/seed_${SEED}"
  SEED_LOG_DIR="${LOG_DIR}/seed_${SEED}"

  rm -rf "$OUT" "$SEED_LOG_DIR"
  mkdir -p "$OUT" "$SEED_LOG_DIR"

  echo
  echo "---------------------------------------"
  echo " Running seed: $SEED"
  echo " Output dir:   $OUT"
  echo "---------------------------------------"

  set +e
  xrun \
    -R \
    -64bit \
    -sv \
    -uvm \
    -assert \
    -coverage all \
    -covoverwrite \
    -covworkdir "$COV_DIR" \
    -covtest "${TEST}_seed_${SEED}" \
    -f "$FILELIST" \
    -top "$TOP" \
    -access +rwc \
    -timescale 1ns/1ps \
    +UVM_TESTNAME="$TEST" \
    +UVM_VERBOSITY="$VERBOSITY" \
    +ntb_random_seed="$SEED" \
    -input "$TCL_FILE" \
    -l "$SEED_LOG_DIR/run.log"
  RUN_STATUS=$?
  set -e

  cp "$SEED_LOG_DIR/run.log" "$OUT/run.log"

  read -r SEED_ASSERT SEED_FAIL SEED_UNCHECKED < <(extract_assert_triplet "$OUT/run.log")

  TOTAL_ASSERT_SUM=$((TOTAL_ASSERT_SUM + SEED_ASSERT))
  TOTAL_FAIL_ASSERT_SUM=$((TOTAL_FAIL_ASSERT_SUM + SEED_FAIL))
  TOTAL_UNCHECKED_SUM=$((TOTAL_UNCHECKED_SUM + SEED_UNCHECKED))

  {
    echo "======================================="
    echo " Seed report"
    echo "======================================="
    echo "Test:        $TEST"
    echo "Seed:        $SEED"
    echo "Verbosity:   $VERBOSITY"
    echo "Run status:  $RUN_STATUS"
    echo "Log file:    $OUT/run.log"
  } > "$OUT/seed_report.txt"

  {
    echo "======================================="
    echo " UVM summary - seed $SEED"
    echo "======================================="
    grep -i "UVM_ERROR" "$OUT/run.log" || echo "No UVM_ERROR"
    grep -i "UVM_FATAL" "$OUT/run.log" || echo "No UVM_FATAL"
  } > "$OUT/uvm_summary.txt"

  {
    echo "======================================="
    echo " Assertions summary - seed $SEED"
    echo "======================================="
    echo "Total Assertions    = $SEED_ASSERT"
    echo "Failing Assertions  = $SEED_FAIL"
    echo "Unchecked Assertions= $SEED_UNCHECKED"
    echo
    echo "[Assertion summary lines from log]"
    grep -Ei "Assertion summary|Total Assertions *=|Failing Assertions *=|Unchecked Assertions *=" "$OUT/run.log" \
      || echo "No assertion summary lines found"
    echo
    echo "[Assertion-related messages]"
    grep -Ei '\[SVA\]|assert(ion)? .*fail|assertion failed|\*E,AS|\$error' "$OUT/run.log" \
      || echo "No assertion-related messages found"
    echo
    if [[ "$SEED_FAIL" -eq 0 ]]; then
      echo "[Conclusion] No assertion failures detected for this seed"
    else
      echo "[Conclusion] Assertion failures detected for this seed"
    fi
  } > "$OUT/assertions_summary.txt"

  {
    echo "======================================="
    echo " Coverage summary - seed $SEED"
    echo "======================================="
    echo
    echo "[Functional coverage events]"
    grep -Ei "sampled coverage item|coverage publish|DMA copy check passed|DMA error observed|DMADONE|DMAERR_EXP" "$OUT/run.log" \
      || echo "No functional coverage events found"
    echo
    echo "[Coverage database lines]"
    grep -Ei "coverage setup:|coverage files:|\.ucm|\.ucd|cov_work|testname *:" "$OUT/run.log" \
      || echo "No coverage database lines found"
    echo
    echo "[Coverage-related warnings/info]"
    grep -Ei "COV[A-Z]+|covergroup|FSM extracted|Enabling instrumentation for coverage types" "$OUT/run.log" \
      || echo "No coverage-related warnings/info found"
  } > "$OUT/coverage_summary.txt"

  {
    echo "======================================="
    echo " Coverage artifacts - seed $SEED"
    echo "======================================="
    find "$COV_DIR" -type f \( -name "*.ucm" -o -name "*.ucd" \) | sort || true
  } > "$OUT/coverage_artifacts.txt"

  {
    echo "----- seed $SEED -----"
    grep -Ei "sampled coverage item|coverage publish|DMA copy check passed|DMA error observed|DMADONE|DMAERR_EXP" "$OUT/run.log" || true
    echo
  } >> "$FUNC_COV_EVENTS_FILE"

  {
    echo "----- seed $SEED -----"
    grep -Ei "Assertion summary|Total Assertions *=|Failing Assertions *=|Unchecked Assertions *=|\[SVA\]|assert(ion)? .*fail|assertion failed|\*E,AS|\$error" "$OUT/run.log" || true
    echo
  } >> "$ASSERT_EVENTS_FILE"

  if [[ "$RUN_STATUS" -eq 0 ]] \
     && ! has_uvm_failures "$OUT/run.log" \
     && [[ "$SEED_FAIL" -eq 0 ]] \
     && ! has_assert_failures "$OUT/run.log"; then
    echo "[RESULT] SEED $SEED: PASS"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "[RESULT] SEED $SEED: FAIL"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAILED_SEEDS="$FAILED_SEEDS $SEED"
  fi
done

# =======================================
# Consolidated reports
# =======================================
cat > "$REG_OUT/regression_summary.txt" <<EOF
=======================================
Regression summary
=======================================
Test:         $TEST
Seeds run:    ${#SEED_LIST[@]}
Passed:       $PASS_COUNT
Failed:       $FAIL_COUNT
Failed seeds: ${FAILED_SEEDS:-none}

Assertions:
  Total (sum):        $TOTAL_ASSERT_SUM
  Failing (sum):      $TOTAL_FAIL_ASSERT_SUM
  Unchecked (sum):    $TOTAL_UNCHECKED_SUM

Coverage dir: $COV_DIR
Logs dir:     $LOG_DIR
=======================================
EOF

{
  echo "======================================="
  echo " Regression assertions report"
  echo "======================================="
  echo
  echo "[Per-seed totals]"
  for SEED in "${SEED_LIST[@]}"; do
    OUT="${REG_OUT}/seed_${SEED}"
    echo "Seed $SEED:"
    grep -Ei "Total Assertions *=|Failing Assertions *=|Unchecked Assertions *=" "$OUT/run.log" || echo "No assertion totals found"
    echo
  done
  echo "[Consolidated sums]"
  echo "Total Assertions (sum)     = $TOTAL_ASSERT_SUM"
  echo "Failing Assertions (sum)   = $TOTAL_FAIL_ASSERT_SUM"
  echo "Unchecked Assertions (sum) = $TOTAL_UNCHECKED_SUM"
  echo
  echo "[Detailed assertion events from logs]"
  cat "$ASSERT_EVENTS_FILE"
  echo
  if [[ "$TOTAL_FAIL_ASSERT_SUM" -eq 0 ]]; then
    echo "[Conclusion] No assertion failures detected across regression"
  else
    echo "[Conclusion] Assertion failures detected across regression"
  fi
} > "$REG_OUT/assertions_report.txt"

{
  echo "======================================="
  echo " Regression coverage report"
  echo "======================================="
  echo
  echo "[Build instrumentation]"
  cat "$REG_OUT/build_report.txt"
  echo
  echo "[Functional coverage events from logs]"
  cat "$FUNC_COV_EVENTS_FILE"
  echo
  echo "[Coverage database artifacts]"
  find "$COV_DIR" -type f \( -name "*.ucm" -o -name "*.ucd" \) | sort || true
} > "$REG_OUT/coverage_report.txt"

{
  echo "======================================="
  echo " Coverage database index"
  echo "======================================="
  find "$COV_DIR" -type f | sort || true
} > "$REG_OUT/coverage_db_index.txt"

rm -f "$FUNC_COV_EVENTS_FILE" "$ASSERT_EVENTS_FILE"

echo
cat "$REG_OUT/regression_summary.txt"

echo
echo "Generated reports:"
echo "  $REG_OUT/build_report.txt"
echo "  $REG_OUT/regression_summary.txt"
echo "  $REG_OUT/assertions_report.txt"
echo "  $REG_OUT/coverage_report.txt"
echo "  $REG_OUT/coverage_db_index.txt"

if [[ "$FAIL_COUNT" -ne 0 ]]; then
  exit 1
fi
