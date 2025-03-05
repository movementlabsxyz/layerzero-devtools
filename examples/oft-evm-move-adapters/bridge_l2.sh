#!/bin/bash

RPC_URL="https://testnet.bardock.movementnetwork.xyz/v1"

AMOUNT="1" # only sending back 1 token

# EXPORT YOUR PRIVATE_KEY TO THE ENVIRONMENT BEFORE PROCEEDING
# REQUIRES APTOS CLI TO BE INSTALLED

# OFT Adapter addresses

# token addresses
USDC_TOKEN="0x4d2969d384e440db9f1a51391cfc261d1ec08ee1bdf7b9711a6c05d485a4110a"
USDT_TOKEN="0x38cdb3f0afabee56a3393793940d28214cba1f5781e13d5db18fa7079f60ab55"
WETH_TOKEN="0x3dfe1ac4574c7dbbe6f1c5ba862de88fc3e7d3cf8eba95ef1abf32b582889e6d"
WBTC_TOKEN="0xbdf86868a32dbae96f2cd50ab05b4be43b92e84e793a4fc01b5b460cc38fdc14"

# Recipient address in ETHEREUM
RECIPIENT_ADDRESS="0xB2105464215716e1445367BEA5668F581eF7d063"
# Caller address in MOVEMENT
PUBLIC_ADDRESS="0x275f508689de8756169d1ee02d889c777de1cebda3a7bbcce63ba8a27c563c6f"

TARGET_EID=30101 #MAINNET

process_asset() {
    local TOKEN_ADDRESS=$1
    local ASSET_NAME=$2

    RECIPIENT_ADDRESS="0x$(printf "%064s" "${RECIPIENT_ADDRESS#0x}" | sed 's/ /0/g')"

    # requires balance in Movement
    echo "Processing $ASSET_NAME..."

    echo "Quoting transfer fee for $ASSET_NAME..."
    #  quote_send(address, u32, vector<u8>, u64, u64, vector<u8>, vector<u8>, vector<u8>, bool)
    QUOTE_RESULT=$(aptos move view --function-id $TOKEN_ADDRESS::oft::quote_send --args address:$PUBLIC_ADDRESS u32:$TARGET_EID hex:$RECIPIENT_ADDRESS u64:$AMOUNT u64:$AMOUNT hex:0x hex:0x hex:0x "bool:false")
    QUOTE_RESULT=$(echo "$QUOTE_RESULT" | jq -r '.Result[0]')
    echo    "QUOTE_RESULT: $QUOTE_RESULT"
    NATIVE_FEE_HEX=$(echo "$QUOTE_RESULT" | cut -c 1-66)
    NATIVE_FEE=$(cast --to-dec "$NATIVE_FEE_HEX")

    echo "Quoted native fee for $ASSET_NAME: $NATIVE_FEE"

    # Send the tokens
    echo "Sending $ASSET_NAME..."
    # send_withdraw(account: &signer, dst_eid: u32, to: vector<u8>, amount_ld: u64, min_amount_ld: u64, extra_options: vector<u8>, compose_message: vector<u8>, oft_cmd: vector<u8>, native_fee: u64, zro_fee: u64,)
    aptos move run --function-id $TOKEN_ADDRESS::oft::send_withdraw --args u32:$TARGET_EID hex:$RECIPIENT_ADDRESS u64:$AMOUNT u64:$AMOUNT hex:0x hex:0x hex:0x u64:$NATIVE_FEE u64:0 --assume-yes
    echo "$ASSET_NAME processing complete."
}

# Process each asset
# aptos init --network custom --rest-url $RPC_URL --skip-faucet --private-key $PRIVATE_KEY --assume-yes 
process_asset "$USDC_TOKEN" "USDC"
process_asset "$USDT_TOKEN" "USDT"
process_asset "$WETH_TOKEN" "WETH"
process_asset "$WBTC_TOKEN" "WBTC"

echo "All transactions completed."
