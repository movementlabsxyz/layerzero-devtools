#!/bin/bash

RPC_URL="https://eth-mainnet.g.alchemy.com/v2/mpa0KayfzqNQdz-kzevYsaZKyRIw-SJL"

AMOUNT="1" 

# EXPORT YOUR PRIVATE_KEY TO THE ENVIRONMENT BEFORE PROCEEDING

# OFT Adapter addresses
MOVE_OFT_ADAPTER="0xf1df43a3053cd18e477233b59a25fc483c2cbe0f"

# Mock token addresses
MOVE_TOKEN="0x3073f7aAA4DB83f95e9FFf17424F71D4751a3073"

# Max uint256 for approval
MAX_UINT256="115792089237316195423570985008687907853269984665640564039457584007913129639935"

# Caller address in ETHEREUM
PUBLIC_ADDRESS=0xB2105464215716e1445367BEA5668F581eF7d063
# Recipient address in MOVEMENT
RECIPIENT_ADDRESS="0x2c161b0deea3d862fd84758fae35b8096aad5ab0ccec7e5008d88d7f8cf1282a"

TARGET_EID=30325

process_asset() {
    local TOKEN_ADDRESS=$1
    local OFT_ADAPTER=$2
    local ASSET_NAME=$3

    echo "Processing $ASSET_NAME..."
    echo "Checking allowance for $ASSET_NAME..."
    ALLOWANCE=$(cast call "$TOKEN_ADDRESS" "allowance(address,address)" "$PUBLIC_ADDRESS" "$OFT_ADAPTER" --rpc-url "$RPC_URL")

    echo "Allowance for $ASSET_NAME: $ALLOWANCE"

    if [[ "$ALLOWANCE" -lt "$AMOUNT" ]]; then
        echo "Approving $ASSET_NAME for OFT Adapter..."
        cast send "$TOKEN_ADDRESS" --rpc-url "$RPC_URL" "approve(address,uint256)" "$OFT_ADAPTER" "$MAX_UINT256" --private-key "$PRIVATE_KEY"
    fi

    echo "Quoting transfer fee for $ASSET_NAME..."
    QUOTE_RESULT=$(cast call "$OFT_ADAPTER" --rpc-url "$RPC_URL" "quoteSend((uint32,bytes32,uint256,uint256,bytes,bytes,bytes),bool)" "($TARGET_EID,$RECIPIENT_ADDRESS,$AMOUNT,$AMOUNT,0x,0x,0x)" false --private-key "$PRIVATE_KEY")

    NATIVE_FEE_HEX=$(echo "$QUOTE_RESULT" | cut -c 1-66)
    NATIVE_FEE=$(cast --to-dec "$NATIVE_FEE_HEX")


    echo "Quoted native fee for $ASSET_NAME: $NATIVE_FEE"

    # Send the tokens
    echo "Sending $ASSET_NAME..."
    cast send "$OFT_ADAPTER" --rpc-url "$RPC_URL" "send((uint32,bytes32,uint256,uint256,bytes,bytes,bytes),(uint256,uint256),address)" "($TARGET_EID,$RECIPIENT_ADDRESS,$AMOUNT,$AMOUNT,0x,0x,0x)" "($NATIVE_FEE,0)" $PUBLIC_ADDRESS --value "$NATIVE_FEE" --private-key "$PRIVATE_KEY"

    echo "$ASSET_NAME processing complete."
}

# Process each asset
process_asset "$MOVE_TOKEN" "$MOVE_OFT_ADAPTER" "MOVE"

echo "All transactions completed."
