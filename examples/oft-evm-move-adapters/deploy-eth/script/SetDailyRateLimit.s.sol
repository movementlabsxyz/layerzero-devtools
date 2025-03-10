// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Console.sol";
import {MOVEOFTAdapter, RateLimiter, OFTAdapter} from "../src/MOVEOFTAdapter.sol";
import {MOVEMock, ERC20} from "../src/MOVEMock.sol";
import {EnforcedOptionParam} from "layerzerolabs/oapp/contracts/oapp/interfaces/IOAppOptionsType3.sol";

contract DailyRateLimitScript is Script {
    
    // Input your contract address here
    MOVEOFTAdapter public adapter = MOVEOFTAdapter(0xf1dF43A3053cd18E477233B59a25fC483C2cBe0f);

    uint32 public movementEid = 30325;
    uint32 public ethereumEid = 30101;

    function run() public {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);
        RateLimiter.RateLimitConfig[] memory rateLimitConfigs = new RateLimiter.RateLimitConfig[](2);
        rateLimitConfigs[0] = RateLimiter.RateLimitConfig({
            dstEid: movementEid,
            limit: 500 * 1e8,
            window: 1 days
        });
        rateLimitConfigs[1] = RateLimiter.RateLimitConfig({
            dstEid: ethereumEid, // incoming
            limit: 0, // if 0, no incoming limit
            window: 1 days
        });
        adapter.setRateLimits(rateLimitConfigs);
    }
}