// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Console.sol";
import {MOVEOFTAdapter, RateLimiter, OFTAdapter} from "../src/MOVEOFTAdapter.sol";
import {MOVEMock, ERC20} from "../src/MOVEMock.sol";
import {EnforcedOptionParam} from "layerzerolabs/oapp/contracts/oapp/interfaces/IOAppOptionsType3.sol";

contract SetDelegateTransferOwnershipScript is Script {
    
    // Input your contract address here
    address public moveAdapter = 0xf1dF43A3053cd18E477233B59a25fC483C2cBe0f;
    address public usdcAdapter = 0xc209a627a7B0a19F16A963D9f7281667A2d9eFf2;
    address public usdtAdapter = 0x5e87D7e75B272fb7150B4d1a05afb6Bd71474950;
    address public wethAdapter = 0x06E01cB086fea9C644a2C105A9F20cfC21A526e8;
    address public wbtcAdapter = 0xa55688C280E725704CFe8Ea30eD33fE5B91cE6a4;

    address public multisig = 0xd7E22951DE7aF453aAc5400d6E072E3b63BeB7E2;

    function run() public {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        transferOwnership(usdcAdapter, multisig);
        transferOwnership(usdtAdapter, multisig);
        transferOwnership(wethAdapter, multisig);
        transferOwnership(wbtcAdapter, multisig);

        vm.stopBroadcast();
    }

    function transferOwnership(address adapterAddress, address newOwner) public {

        OFTAdapter adapter = OFTAdapter(adapterAddress);
        adapter.setDelegate(newOwner);
        adapter.transferOwnership(newOwner);
    }
}