#!/usr/bin/env bash
set -euo pipefail

########################################
# User config (set via env or edit here)
########################################

# Full Move function ID, e.g.:
# 0xYOUR_OAPP_ADDR::oapp_core::set_config
FUNCTION_ID="${FUNCTION_ID:-0x7e4fd97ef92302eea9b10f74be1d96fb1f1511cf7ed28867b0144ca89c6ebc3c::oapp_core::set_config}"

# Remote EID to configure for (e.g. Ethereum 30101, HyperEVM 30367, etc.)
REMOTE_EID="${REMOTE_EID:-30184}"

# Message libraries (send and receive ULN on Movement)
SEND_LIB_ADDR="${SEND_LIB_ADDR:-0xc33752e0220faf79e45385dd73fb28d681dcd9f1569a1480725507c1f3c3aba9}"
RECV_LIB_ADDR="${RECV_LIB_ADDR:-0xc33752e0220faf79e45385dd73fb28d681dcd9f1569a1480725507c1f3c3aba9}"

# Executor
EXECUTOR_ADDR="${EXECUTOR_ADDR:-0x15a5bbf1eb7998a22c9f23810d424abe40bd59ddd8e6ab7e59529853ebed41c4}"

# DVNs (you MUST override these three)
HORIZEN_DVN="${HORIZEN_DVN:-0x2b696b3ee859b7eb624e1fd5de49f4d3806f49862f1177d6827fd1beffde9179}"
P2P_DVN="${P2P_DVN:-0xbcfb6d3ce5e99275e5fa09b3f53eaaea32365c776d023c51a680c4c420d88b91}"
LZ_DVN="${LZ_DVN:-0xdf8f0a53b20f1656f998504b81259698d126523a31bdbbae45ba1e8a3078d8da}"


# confirmations (ignored if use_default_for_confirmations=true, but still encoded)
SEND_CONFIRMATIONS="${CONFIRMATIONS:-30000}"
RECEIVE_CONFIRMATIONS="${CONFIRMATIONS:-10}"

# Max message size for executor config (u32)
MAX_MESSAGE_SIZE="${MAX_MESSAGE_SIZE:-100000}"

########################################
# Helpers (pure bash)
########################################

# Encode u32 (decimal) as big-endian hex (8 chars)
# Big-endian means most significant byte first (used by LayerZero Move contracts)
u32_be_hex() {
  local n="$1"
  if (( n < 0 || n > 4294967295 )); then
    echo "ERROR: u32 out of range: $n" >&2
    exit 1
  fi
  local b3=$(( (n >>24) & 0xff ))  # Most significant byte
  local b2=$(( (n >>16) & 0xff ))
  local b1=$(( (n >> 8) & 0xff ))
  local b0=$(( n        & 0xff ))  # Least significant byte
  printf "%02x%02x%02x%02x" "$b3" "$b2" "$b1" "$b0"
}

# Encode u64 (decimal) as big-endian hex (16 chars)
u64_be_hex() {
  local n="$1"
  if (( n < 0 )); then
    echo "ERROR: u64 must be non-negative: $n" >&2
    exit 1
  fi
  printf "%016x" "$n"
}

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
# Build ULNConfig BCS
#
# struct UlnConfig {
#   confirmations: u64,
#   optional_dvn_threshold: u8,
#   required_dvns: vector<address>,
#   optional_dvns: vector<address>,
#   use_default_for_confirmations: bool,
#   use_default_for_required_dvns: bool,
#   use_default_for_optional_dvns: bool,
# }
#
# You requested:
#   confirmations = 0
#   required_dvns = [horizen, lz, p2p] (sorted)
#   optional_dvns = []
#   optional_dvn_threshold = 0
#   use_default_for_confirmations = true
#   use_default_for_required_dvns = false
#   use_default_for_optional_dvns = false
########################################

# confirmations: u64 big-endian (0) -> 8 zero bytes
SEND_CONFIRMATIONS_U64_HEX="$(u64_be_hex "$SEND_CONFIRMATIONS")"
RECEIVE_CONFIRMATIONS_U64_HEX="$(u64_be_hex "$RECEIVE_CONFIRMATIONS")"

# optional_dvn_threshold: u8 (0)
OPTIONAL_DVN_THRESHOLD_HEX="00"

# Strip 0x prefixes from DVN addresses
HORIZEN_DVN_CLEAN="${HORIZEN_DVN#0x}"
P2P_DVN_CLEAN="${P2P_DVN#0x}"
LZ_DVN_CLEAN="${LZ_DVN#0x}"

REQUIRED_DVNS_HEX="${HORIZEN_DVN_CLEAN}${P2P_DVN_CLEAN}${LZ_DVN_CLEAN}"

# required_dvns: vector<address>
#   length = 3 -> ULEB128(3) = 0x03 (single byte)
REQUIRED_DVNS_VEC_PREFIX="03"  # length
REQUIRED_DVNS_VEC_HEX="${REQUIRED_DVNS_VEC_PREFIX}${REQUIRED_DVNS_HEX}"

# optional_dvns: empty vector<address> -> length 0 => 0x00
OPTIONAL_DVNS_VEC_HEX="00"

# use_default_* booleans
# true  -> 0x01
# false -> 0x00
USE_DEFAULT_FOR_CONFIRMATIONS_HEX="00"
USE_DEFAULT_FOR_REQUIRED_DVNS_HEX="00"
USE_DEFAULT_FOR_OPTIONAL_DVNS_HEX="00"

SEND_ULN_CONFIG_BODY_HEX="${SEND_CONFIRMATIONS_U64_HEX}${OPTIONAL_DVN_THRESHOLD_HEX}${REQUIRED_DVNS_VEC_HEX}${OPTIONAL_DVNS_VEC_HEX}${USE_DEFAULT_FOR_CONFIRMATIONS_HEX}${USE_DEFAULT_FOR_REQUIRED_DVNS_HEX}${USE_DEFAULT_FOR_OPTIONAL_DVNS_HEX}"
SEND_ULN_CONFIG_HEX="0x${SEND_ULN_CONFIG_BODY_HEX}"
RECEIVE_ULN_CONFIG_BODY_HEX="${RECEIVE_CONFIRMATIONS_U64_HEX}${OPTIONAL_DVN_THRESHOLD_HEX}${REQUIRED_DVNS_VEC_HEX}${OPTIONAL_DVNS_VEC_HEX}${USE_DEFAULT_FOR_CONFIRMATIONS_HEX}${USE_DEFAULT_FOR_REQUIRED_DVNS_HEX}${USE_DEFAULT_FOR_OPTIONAL_DVNS_HEX}"
RECEIVE_ULN_CONFIG_HEX="0x${RECEIVE_ULN_CONFIG_BODY_HEX}"

########################################
# Build ExecutorConfig BCS
#
# struct ExecutorConfig {
#   max_message_size: u32,
#   executor_address: address,
# }
########################################

MAX_MESSAGE_SIZE_HEX="$(u32_be_hex "$MAX_MESSAGE_SIZE")"

# Strip 0x prefix from executor address
EXECUTOR_ADDR_CLEAN="${EXECUTOR_ADDR#0x}"

EXECUTOR_CONFIG_BODY_HEX="${MAX_MESSAGE_SIZE_HEX}${EXECUTOR_ADDR_CLEAN}"
EXECUTOR_CONFIG_HEX="0x${EXECUTOR_CONFIG_BODY_HEX}"

########################################
# Show payloads
########################################

echo "SEND_ULN_CONFIG_HEX      = ${SEND_ULN_CONFIG_HEX}"
echo "SEND_ULN_CONFIG_VEC      = $(hex_to_vec_u8 "${SEND_ULN_CONFIG_HEX}")"
echo "RECEIVE_ULN_CONFIG_HEX      = ${RECEIVE_ULN_CONFIG_HEX}"
echo "RECEIVE_ULN_CONFIG_VEC      = $(hex_to_vec_u8 "${RECEIVE_ULN_CONFIG_HEX}")"
echo
echo "EXECUTOR_CONFIG_HEX = ${EXECUTOR_CONFIG_HEX}"
echo "EXECUTOR_CONFIG_VEC = $(hex_to_vec_u8 "${EXECUTOR_CONFIG_HEX}")"
echo