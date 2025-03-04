// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {USDCOFTAdapter} from "../src/USDCOFTAdapter.sol";
import {USDTOFTAdapter} from "../src/USDTOFTAdapter.sol";
import {WETHOFTAdapter} from "../src/WETHOFTAdapter.sol";
import {WBTCOFTAdapter} from "../src/WBTCOFTAdapter.sol";
import {EnforcedOptionParam} from "layerzerolabs/oapp/contracts/oapp/interfaces/IOAppOptionsType3.sol";

contract OFTAdaptersScript is Script {
    // Mainnet
    address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    address public lzEndpoint = 0x1a44076050125825900e736c501f859c50fE728c;
    uint32 public movementEid = 30325;

    USDCOFTAdapter public usdcA;
    USDTOFTAdapter public usdtA;
    WETHOFTAdapter public wethA;
    WBTCOFTAdapter public wbtcA;
    // Enforced options: worker -> gas units
    bytes public options = abi.encodePacked(uint176(0x00030100110100000000000000000000000000030D40));
    // Movement MOVEOFTAdapter in bytes32
    bytes32 public usdcOftAdapterBytes32 = 0x60e936500b90baa57aa560ccd8e0b037419c028905e78ab7df5ed88f682a2529;
    bytes32 public usdtOftAdapterBytes32 = 0x079f3ba28add0f0c113c0799d6e92e8538c02f1ce2d9ad4ca45929907b77bdc9;
    bytes32 public wethOftAdapterBytes32 = 0xead494f359ae1e57cf850bae3afb1460b1352e7396dfedd2ec494295d33cc99a;
    bytes32 public wbtcOftAdapterBytes32 = 0xb42d482d7a80d56c03493f8bd652504f1f7f67e2f66183b1854f3b162ef798bb;

    function run() public {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);
        address owner = vm.addr(pk);

        // Deploy the adapter
        usdcA = new USDCOFTAdapter(usdc, lzEndpoint, owner);
        usdtA = new USDTOFTAdapter(usdt, lzEndpoint, owner);
        wethA = new WETHOFTAdapter(weth, lzEndpoint, owner);
        wbtcA = new WBTCOFTAdapter(wbtc, lzEndpoint, owner);

        usdcA.setPeer(movementEid, usdcOftAdapterBytes32);
        usdtA.setPeer(movementEid, usdtOftAdapterBytes32);
        wethA.setPeer(movementEid, wethOftAdapterBytes32);
        wbtcA.setPeer(movementEid, wbtcOftAdapterBytes32);

        EnforcedOptionParam[] memory enforcedParams = new EnforcedOptionParam[](2);
        enforcedParams[0] = EnforcedOptionParam({eid: movementEid, msgType: uint16(1), options: options});
        enforcedParams[1] = EnforcedOptionParam({eid: movementEid, msgType: uint16(2), options: options});

        usdcA.setEnforcedOptions(enforcedParams);
        usdtA.setEnforcedOptions(enforcedParams);
        wethA.setEnforcedOptions(enforcedParams);
        wbtcA.setEnforcedOptions(enforcedParams);
    }
}
