#!/bin/bash

RPC_URL="https://eth.llamarpc.com"

AMOUNT="1"

# EXPORT YOUR PRIVATE_KEY TO THE ENVIRONMENT BEFORE PROCEEDING

# OFT Adapter addresses
USDC_OFT_ADAPTER="0xc209a627a7B0a19F16A963D9f7281667A2d9eFf2"
USDT_OFT_ADAPTER="0x5e87D7e75B272fb7150B4d1a05afb6Bd71474950"
WETH_OFT_ADAPTER="0x06E01cB086fea9C644a2C105A9F20cfC21A526e8"
WBTC_OFT_ADAPTER="0xa55688C280E725704CFe8Ea30eD33fE5B91cE6a4"


# Mock token addresses
USDC_TOKEN="0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
USDT_TOKEN="0xdac17f958d2ee523a2206206994597c13d831ec7"
WETH_TOKEN="0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
WBTC_TOKEN="0x2260fac5e5542a773aa44fbcfedf7c193bc2c599"

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
    
    # IF MAINNET YOU NEED BALANCE PRIOR TO THIS
    if [[ $TARGET_EID -eq 40325 ]]; then
        echo "Minting $ASSET_NAME..."
        cast send "$TOKEN_ADDRESS" "mint(address,uint256)" "$PUBLIC_ADDRESS"  "$AMOUNT" --rpc-url "$RPC_URL" --private-key "$PRIVATE_KEY"
    fi

    echo "Checking allowance for $ASSET_NAME..."
    ALLOWANCE=$(cast call "$TOKEN_ADDRESS" "allowance(address,address)" "$PUBLIC_ADDRESS" "$OFT_ADAPTER" --rpc-url "$RPC_URL")

    ALLOWANCE_IN_DECIMALS=$(cast --to-dec "$ALLOWANCE")

    echo "Allowance for $ASSET_NAME: $ALLOWANCE_IN_DECIMALS"

    if [[ "$ALLOWANCE_IN_DECIMALS" -gt "$AMOUNT" ]]; then
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
process_asset "$USDC_TOKEN" "$USDC_OFT_ADAPTER" "USDC"
process_asset "$USDT_TOKEN" "$USDT_OFT_ADAPTER" "USDT"
process_asset "$WETH_TOKEN" "$WETH_OFT_ADAPTER" "WETH"
process_asset "$WBTC_TOKEN" "$WBTC_OFT_ADAPTER" "WBTC"

echo "All transactions completed."
