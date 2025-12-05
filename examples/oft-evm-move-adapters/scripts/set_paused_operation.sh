#!/usr/bin/env bash
set -euo pipefail

########################################
# Build ABI-encoded operation data for:
# set_paused(caller: signer, paused: bool)
# on 0x7e4fd97ef92302eea9b10f74be1d96fb1f1511cf7ed28867b0144ca89c6ebc3c::move_oft_adapter::set_paused
########################################

# User config (set via env or edit here)
########################################

# Full Move function ID
FUNCTION_ID="${FUNCTION_ID:-0x7e4fd97ef92302eea9b10f74be1d96fb1f1511cf7ed28867b0144ca89c6ebc3c::move_oft_adapter::set_paused}"

# Paused state (true or false)
PAUSED="${PAUSED:-true}"

########################################
# Helpers
########################################

# Convert hex string to vec<u8> format
hex_to_vec_u8() {
  local hex="$1"
  # Remove 0x prefix if present
  hex="${hex#0x}"

  # Build the vec<u8> representation
  local result="["
  local first=true

  for ((i=0; i<${#hex}; i+=2)); do
    local byte="${hex:$i:2}"
    local decimal=$((16#$byte))

    if [ "$first" = true ]; then
      result="${result}${decimal}"
      first=false
    else
      result="${result}, ${decimal}"
    fi
  done

  result="${result}]"
  echo "$result"
}

########################################
# Build operation data
#
# For set_paused(caller: signer, paused: bool):
# - caller: signer (this is handled by the transaction itself, not in the data)
# - paused: bool (encoded as 0x01 for true, 0x00 for false)
#
# BCS encoding for bool:
# - false = 0x00
# - true  = 0x01
########################################

if [ "$PAUSED" = "true" ]; then
  PAUSED_HEX="01"
else
  PAUSED_HEX="00"
fi

OPERATION_DATA_HEX="0x${PAUSED_HEX}"

########################################
# Show output
########################################

echo "========================================="
echo "set_paused Operation Data"
echo "========================================="
echo
echo "Function ID: ${FUNCTION_ID}"
echo "Paused:      ${PAUSED}"
echo
echo "OPERATION_DATA_HEX = ${OPERATION_DATA_HEX}"
echo "OPERATION_DATA_VEC = $(hex_to_vec_u8 "${OPERATION_DATA_HEX}")"
echo
echo "========================================="
echo "Usage in Move CLI:"
echo "========================================="
echo
echo "movement move run \\"
echo "  --function-id \"${FUNCTION_ID}\" \\"
echo "  --args bool:${PAUSED}"
echo
