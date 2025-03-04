// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Console.sol";
import {MOVEOFTAdapter, RateLimiter, OFTAdapter} from "../src/MOVEOFTAdapter.sol";
import {MOVEMock, ERC20} from "../src/MOVEMock.sol";
import {EnforcedOptionParam} from "layerzerolabs/oapp/contracts/oapp/interfaces/IOAppOptionsType3.sol";

contract DailyRateLimitScript is Script {
    
    // Input your contract address here
    MOVEOFTAdapter public adapter = MOVEOFTAdapter(address(0x2104D31cCB7ACEDc572bDA19367A3AaF52E2ff5e));

    uint32 public movementEid = 40325;
    uint32 public incomingEid = 40102;

    function run() public {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);
        RateLimiter.RateLimitConfig[] memory rateLimitConfigs = new RateLimiter.RateLimitConfig[](2);
        rateLimitConfigs[0] = RateLimiter.RateLimitConfig({
            dstEid: movementEid,
            limit: 75000000 * 1e8,
            window: 1 days
        });
        rateLimitConfigs[1] = RateLimiter.RateLimitConfig({
            dstEid: incomingEid, // incoming
            limit: 0, // if 0, no incoming limit
            window: 1 days
        });
        adapter.setRateLimits(rateLimitConfigs);
    }
}