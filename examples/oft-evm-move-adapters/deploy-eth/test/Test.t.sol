import {MOVEOFTAdapter, RateLimiter} from "../src/MOVEOFTAdapter.sol";
import {Test} from "forge-std/Test.sol";

contract TransferTest is Test {

    address public multisig = 0xd7E22951DE7aF453aAc5400d6E072E3b63BeB7E2;
address public moveAdapter = 0xf1dF43A3053cd18E477233B59a25fC483C2cBe0f;
address public signer = 0xB2105464215716e1445367BEA5668F581eF7d063;

    function testTransfer() public {
        MOVEOFTAdapter adapter = MOVEOFTAdapter(moveAdapter);
        vm.startPrank(signer);
        adapter.setDelegate(multisig);
        adapter.transferOwnership(multisig);
        vm.stopPrank();

        RateLimiter.RateLimitConfig[] memory rateLimitConfigs = new RateLimiter.RateLimitConfig[](1);

        rateLimitConfigs[0] = RateLimiter.RateLimitConfig({
            dstEid: 30325,
            limit: 75000000 * 1e8,
            window: 1 days
        });

        vm.prank(multisig);
        adapter.setRateLimits(rateLimitConfigs);
    }
}