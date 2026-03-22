#!/usr/bin/env bash

set -euo pipefail

# =======================================
# User config
# =======================================
TEST="${1:-tb_directed}"
TOP="${2:-tb_directed}"
SEED="${3:-1}"

FILELIST="scripts/filelist_directed.f"

SIM_ROOT="sim"
OUT="${SIM_ROOT}/directed/${TEST}/seed_${SEED}"
LOG_DIR="${OUT}/logs"
WAVE_DIR="${OUT}/waves"

echo "======================================="
echo " Running directed simulation"
echo " Test:         $TEST"
echo " Top:          $TOP"
echo " Seed:         $SEED"
echo " Output:       $OUT"
echo "======================================="

rm -rf "$OUT"
mkdir -p "$LOG_DIR" "$WAVE_DIR"

# =======================================
# Compile
# =======================================
echo "[RUN] Compiling directed testbench..."

xrun \
  -64bit \
  -sv \
  -f "$FILELIST" \
  -top "$TOP" \
  -access +rwc \
  -timescale 1ns/1ps \
  -l "$LOG_DIR/compile.log" \
  -elaborate

echo "[RUN] Compile done."

# =======================================
# Run
# =======================================
echo "[RUN] Running directed simulation..."

set +e
xrun \
  -R \
  -64bit \
  -sv \
  -f "$FILELIST" \
  -top "$TOP" \
  -access +rwc \
  -timescale 1ns/1ps \
  +ntb_random_seed="$SEED" \
  -l "$LOG_DIR/run.log"
RUN_STATUS=$?
set -e

# =======================================
# Collect waveforms
# =======================================
for f in *.vcd *.fsdb; do
  [ -e "$f" ] || continue
  mv "$f" "$WAVE_DIR/"
done

if [ -d waves.shm ]; then
  mv waves.shm "$WAVE_DIR/"
fi

# =======================================
# Summary
# =======================================
{
  echo "======================================="
  echo " Directed simulation summary"
  echo "======================================="
  echo "Test:       $TEST"
  echo "Top:        $TOP"
  echo "Seed:       $SEED"
  echo "Exit code:  $RUN_STATUS"
  echo
  echo "[Compile log]"
  echo "$LOG_DIR/compile.log"
  echo
  echo "[Run log]"
  echo "$LOG_DIR/run.log"
  echo
  echo "[Waveforms]"
  find "$WAVE_DIR" -maxdepth 1 -mindepth 1 | sort || true
  echo
  if [ "$RUN_STATUS" -eq 0 ]; then
    echo "[Conclusion] Directed simulation finished successfully"
  else
    echo "[Conclusion] Directed simulation failed"
  fi
} > "$OUT/summary.txt"

echo
cat "$OUT/summary.txt"

if [ "$RUN_STATUS" -ne 0 ]; then
  exit 1
fi
