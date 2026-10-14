#!/bin/bash
# GUI build: same sources as the measurement build, with RENDER=1.
#   scripts/build_inline_led.sh [STATE] [LED_DELAY]   -> inline_led.elf
# In Ripes, add an LED Matrix in the I/O tab with Width 35 and Height 25.
set -euo pipefail
STATE="${1:-74523162333332}"
export LED_DELAY="${2:-2000}"
export RENDER=1
exec "$(dirname "$0")/build_inline_target.sh" "$STATE"
