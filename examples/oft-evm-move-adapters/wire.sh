#!/bin/bash

RPC_URL="https://eth-mainnet.g.alchemy.com/v2/mpa0KayfzqNQdz-kzevYsaZKyRIw-SJL"

AMOUNT="1" 

# EXPORT YOUR PRIVATE_KEY TO THE ENVIRONMENT BEFORE PROCEEDING
USDC_A=0xc209a627a7B0a19F16A963D9f7281667A2d9eFf2
USDT_A=0x5e87D7e75B272fb7150B4d1a05afb6Bd71474950
WETH_A=0x06E01cB086fea9C644a2C105A9F20cfC21A526e8
WBTC_A=0xa55688C280E725704CFe8Ea30eD33fE5B91cE6a4

USDC=0x4d2969d384e440db9f1a51391cfc261d1ec08ee1bdf7b9711a6c05d485a4110a
USDT=0x38cdb3f0afabee56a3393793940d28214cba1f5781e13d5db18fa7079f60ab55
WETH=0x3dfe1ac4574c7dbbe6f1c5ba862de88fc3e7d3cf8eba95ef1abf32b582889e6d
WBTC=0xbdf86868a32dbae96f2cd50ab05b4be43b92e84e793a4fc01b5b460cc38fdc14

TARGET_EID=30325

process_asset() {
    local TOKEN_ADDRESS=$1
    local OFT_ADAPTER=$2
    local ASSET_NAME=$3

    echo "Processing $ASSET_NAME..."
    echo "Checking allowance for $ASSET_NAME..."
    
    cast send $OFT_ADAPTER "setPeer(uint32,bytes32)" 30325 "$TOKEN_ADDRESS" --rpc-url https://eth.llamarpc.com --private-key $PRIVATE_KEY
}

# Process each asset
process_asset "$USDC" "$USDC_A" "USDC"
process_asset "$USDT" "$USDT_A" "USDT"
process_asset "$WETH" "$WETH_A" "WETH"
process_asset "$WBTC" "$WBTC_A" "WBTC"

echo "All transactions completed."
