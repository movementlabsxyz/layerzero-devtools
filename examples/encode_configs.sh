#!/bin/bash
# ============================================================
# LayerZero V2 Aptos Move Config Encoder
# Generates big-endian encoded vector<u8> for set_config():
#   config_type 1 = ExecutorConfig
#   config_type 2 = SendUln (UlnConfig)
#   config_type 3 = RecvUln (UlnConfig)
#
# Usage:
#   source encode_configs.sh
#
#   read -r EXECUTOR_CFG SEND_ULN_CFG RECV_ULN_CFG <<< "$(encode_lz_configs \
#       false 10 10 \
#       false \
#       true \
#       "addr1,addr2,addr3" "" \
#       <executor_address> 10000 <uln_address>)"
# ============================================================

# ============================================================
# Encoding Helpers (big-endian)
# ============================================================

_encode_u8() {
    printf "%02x" "$1"
}

_encode_u32() {
    local val=$1
    printf "%02x%02x%02x%02x" \
        $(((val >> 24) & 0xFF)) \
        $(((val >> 16) & 0xFF)) \
        $(((val >> 8) & 0xFF)) \
        $((val & 0xFF))
}

_encode_u64() {
    local val=$1
    printf "%02x%02x%02x%02x%02x%02x%02x%02x" \
        $(((val >> 56) & 0xFF)) \
        $(((val >> 48) & 0xFF)) \
        $(((val >> 40) & 0xFF)) \
        $(((val >> 32) & 0xFF)) \
        $(((val >> 24) & 0xFF)) \
        $(((val >> 16) & 0xFF)) \
        $(((val >> 8) & 0xFF)) \
        $((val & 0xFF))
}

_encode_bool() {
    if [ "$1" = true ] || [ "$1" = "1" ]; then
        printf "01"
    else
        printf "00"
    fi
}

_encode_uleb128() {
    local val=$1
    local result=""
    while [ "$val" -ge 128 ]; do
        result="${result}$(printf "%02x" $(((val & 0x7F) | 0x80)))"
        val=$((val >> 7))
    done
    result="${result}$(printf "%02x" "$val")"
    echo -n "$result"
}

_encode_address() {
    local addr="${1#0x}"
    addr="${addr// /}"
    printf "%064s" "$addr" | tr ' ' '0'
}

# ============================================================
# encode_lz_configs
#
# DVN addresses are passed as comma-separated strings.
# optional_dvn_threshold is derived from the optional_dvns length
#
# Arguments (positional):
#   $1  use_default_confirmations  bool - use default confirmations (send & recv)
#   $2  send_confirmations_amount  u64  - send confirmation count (ignored if $1=true)
#   $3  recv_confirmations_amount  u64  - recv confirmation count (ignored if $1=true)
#   $4  use_default_required_dvns  bool - use default required DVNs
#   $5  use_default_optional_dvns  bool - use default optional DVNs
#   $6  required_dvns              str  - comma-separated required DVN addresses
#   $7  optional_dvns              str  - comma-separated optional DVN addresses
#   $8  executor_address           addr - executor bytes32 address
#   $9  max_message_size           u32  - executor max message size
#   $10 uln_address                addr - ULN address (shared send/recv)
#
# Output: three space-separated hex strings (no 0x prefix)
#   EXECUTOR_CONFIG SEND_ULN_CONFIG RECV_ULN_CONFIG
#
# Example:
#   read -r EX SEND RECV <<< "$(encode_lz_configs \
#       false 10 10 \
#       false \
#       true \
#       "2b696b...,bcfb6d...,df8f0a..." "" \
#       $executor 10000 $msg_lib)"
# ============================================================

encode_lz_configs() {
    local use_default_confirmations="$1"
    local send_confirmations_amount="$2"
    local recv_confirmations_amount="$3"
    local use_default_required_dvns="$4"
    local use_default_optional_dvns="$5"
    local required_dvns_csv="$6"
    local optional_dvns_csv="$7"
    local executor_address="$8"
    local max_message_size="$9"
    local uln_address="${10}"

    # Split comma-separated DVN strings into arrays and sort ascending (big-endian)
    local required_dvns=()
    if [ -n "$required_dvns_csv" ]; then
        IFS=',' read -ra required_dvns <<< "$required_dvns_csv"
        IFS=$'\n' required_dvns=($(for d in "${required_dvns[@]}"; do
            echo "${d#0x}" | tr '[:upper:]' '[:lower:]'
        done | sort)); unset IFS
    fi
    local optional_dvns=()
    if [ -n "$optional_dvns_csv" ]; then
        IFS=',' read -ra optional_dvns <<< "$optional_dvns_csv"
        IFS=$'\n' optional_dvns=($(for d in "${optional_dvns[@]}"; do
            echo "${d#0x}" | tr '[:upper:]' '[:lower:]'
        done | sort)); unset IFS
    fi

    # Derive optional_dvn_threshold from optional_dvns length
    local optional_dvn_threshold=${#optional_dvns[@]}

    # --- Validation ---
    if [ "$use_default_required_dvns" = false ] && [ "${#required_dvns[@]}" -eq 0 ]; then
        echo "ERROR: use_default_required_dvns=false but REQUIRED_DVNS is empty" >&2
        return 1
    fi

    # --- Executor Config ---
    local executor_cfg=""
    executor_cfg+=$(_encode_u32 "$max_message_size")
    executor_cfg+=$(_encode_address "$executor_address")

    # --- helper: encode UlnConfig ---
    # $1 = confirmations amount for this direction
    _encode_uln() {
        local conf_amount="$1"
        local result=""
        # confirmations: u64
        if [ "$use_default_confirmations" = true ]; then
            result+=$(_encode_u64 0)
        else
            result+=$(_encode_u64 "$conf_amount")
        fi
        # optional_dvn_threshold: u8
        if [ "$use_default_optional_dvns" = true ]; then
            result+=$(_encode_u8 0)
        else
            result+=$(_encode_u8 "$optional_dvn_threshold")
        fi
        # required_dvns: vector<address>
        if [ "$use_default_required_dvns" = false ]; then
            result+=$(_encode_uleb128 "${#required_dvns[@]}")
            for dvn in "${required_dvns[@]}"; do
                result+=$(_encode_address "$dvn")
            done
        else
            result+=$(_encode_uleb128 0)
        fi
        # optional_dvns: vector<address>
        if [ "$use_default_optional_dvns" = false ]; then
            result+=$(_encode_uleb128 "${#optional_dvns[@]}")
            for dvn in "${optional_dvns[@]}"; do
                result+=$(_encode_address "$dvn")
            done
        else
            result+=$(_encode_uleb128 0)
        fi
        # use_default bools
        result+=$(_encode_bool "$use_default_confirmations")
        result+=$(_encode_bool "$use_default_required_dvns")
        result+=$(_encode_bool "$use_default_optional_dvns")
        echo -n "$result"
    }

    local send_uln_cfg=$(_encode_uln "$send_confirmations_amount")
    local recv_uln_cfg=$(_encode_uln "$recv_confirmations_amount")

    echo "${executor_cfg} ${send_uln_cfg} ${recv_uln_cfg}"
}
