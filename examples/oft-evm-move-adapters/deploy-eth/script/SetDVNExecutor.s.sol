// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {ExecutorConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/SendLibBase.sol";
import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {SetConfigParam} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import {UlnConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";

contract DVNExecutorScript is Script {
    // Input your contract address here
    address public moveAdapter = 0xf1dF43A3053cd18E477233B59a25fC483C2cBe0f;
    address public usdcAdapter = 0xc209a627a7B0a19F16A963D9f7281667A2d9eFf2;
    address public usdtAdapter = 0x5e87D7e75B272fb7150B4d1a05afb6Bd71474950;
    address public wethAdapter = 0x06E01cB086fea9C644a2C105A9F20cfC21A526e8;
    address public wbtcAdapter = 0xa55688C280E725704CFe8Ea30eD33fE5B91cE6a4;

    uint64 public confirmations = 1;

    ILayerZeroEndpointV2 public endpoint = ILayerZeroEndpointV2(0x1a44076050125825900e736c501f859c50fE728c);

    uint32 public movementEid = 30325;

    address public sendUln302 = 0xbB2Ea70C9E858123480642Cf96acbcCE1372dCe1;
    address public receiveUln302 = 0xc02Ab410f0734EFa3F14628780e6e695156024C2;
    address public lzExecutor = 0x173272739Bd7Aa6e4e214714048a9fE699453059;

    address public p2pDVN = 0x06559EE34D85a88317Bf0bfE307444116c631b67;
    address public horizenDVN = 0x380275805876Ff19055EA900CDb2B46a94ecF20D;
    address public lzDVN = 0x589dEDbD617e0CBcB916A9223F4d1300c294236b;
    address public nethermindDVN = 0xa59BA433ac34D2927232918Ef5B2eaAfcF130BA5;


    uint32 public constant EXECUTOR_CONFIG_TYPE = 1;
    uint32 public constant ULN_CONFIG_TYPE = 2;
    uint32 public constant RECEIVE_CONFIG_TYPE = 2;

    function run() public {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        configDVNExecutor(moveAdapter);
        configDVNExecutor(usdcAdapter);
        configDVNExecutor(usdtAdapter);
        configDVNExecutor(wethAdapter);
        configDVNExecutor(wbtcAdapter);

        vm.stopBroadcast();
    }

    function configDVNExecutor(address adapter) public {
        
        setLibraries(adapter, movementEid, sendUln302, receiveUln302);

        address[] memory array = new address[](3);
        array[0] = p2pDVN;
        array[1] = horizenDVN;
        array[2] = lzDVN;

        address[] memory emptyArray = new address[](0);
        UlnConfig memory ulnConfig = UlnConfig(uint64(confirmations), uint8(3), uint8(0), uint8(0), array, emptyArray);
        ExecutorConfig memory executorConfig = ExecutorConfig(0, lzExecutor);
        setConfigs(adapter, movementEid, sendUln302, receiveUln302, ulnConfig, executorConfig);
    }

    function setConfigs(
        address contractAddress,
        uint32 remoteEid,
        address sendLibraryAddress,
        address receiveLibraryAddress,
        UlnConfig memory ulnConfig,
        ExecutorConfig memory executorConfig
    ) internal {
        SetConfigParam[] memory sendConfigParams = new SetConfigParam[](2);

        sendConfigParams[0] =
            SetConfigParam({eid: remoteEid, configType: EXECUTOR_CONFIG_TYPE, config: abi.encode(executorConfig)});

        sendConfigParams[1] =
            SetConfigParam({eid: remoteEid, configType: ULN_CONFIG_TYPE, config: abi.encode(ulnConfig)});

        SetConfigParam[] memory receiveConfigParams = new SetConfigParam[](1);
        receiveConfigParams[0] = SetConfigParam({
            eid: remoteEid,
            configType: RECEIVE_CONFIG_TYPE,
            config: abi.encode(ulnConfig)
        });

        endpoint.setConfig(contractAddress, sendLibraryAddress, sendConfigParams);
        endpoint.setConfig(contractAddress, receiveLibraryAddress, receiveConfigParams);
    }

    function setLibraries(address _oapp, uint32 _eid, address _sendLib, address _receiveLib) internal {
        endpoint.setSendLibrary(_oapp, _eid, _sendLib);
        endpoint.setReceiveLibrary(_oapp, _eid, _receiveLib, 0);
    }
}
