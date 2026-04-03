#!/bin/bash
# Sets Move.toml addresses and framework dependency based on cli + network.
# Usage: source set_move_env.sh && set_move_env <cli> <network>

set_move_env() {
    local cli="$1"
    local network="$2"
    local dir="${3:-.}"
    local env="${cli}-${network}"

    local addresses=""
    local framework_dep=""

    case "$env" in
        aptos-testnet)
            addresses='oft_common = "0xa4c83e48703381fc23d03e3cb89088dbd363c51427fe52f352ce1668b4d146cd"
router_node_0 = "0x7a19f544a6db990a1bfa6d84d0f53f918cd41765ec5b0d67abbdb78455f1d43a"
simple_msglib = "0x98ab4d5f6f5ae0d3bc9d9785cfd63244fffc4652bf54f8971cb7035589a256eb"
blocked_msglib = "0xb79b041ff861c2ec1e67138501270d978a35bd28817565a6752bfc469fa62c06"
uln_302 = "0xcc1c03aed42e2841211865758b5efe93c0dde2cb7a2a5dc6cf25a4e33ad23690"
router_node_1 = "0x8c65dab3f69a5c35eefed1e181f68890021797156dc1842b191b2ece7bda909a"
endpoint_v2_common = "0x3bc8cbd74c2e1929c287a0063206fbb126314976146934bae12283f6120e99e9"
endpoint_v2 = "0x7f03103b83c51c8b09be1751a797a65ac6e755f72947ecdecffc203d32d816c6"
layerzero_admin = "0xb1f42e295868a61b2d78836f1199324c8964c84a54e8ff8f72c5a6594d600d07"
layerzero_treasury_admin = "0xb1f42e295868a61b2d78836f1199324c8964c84a54e8ff8f72c5a6594d600d07"
msglib_types = "0xd34d78d10b19757dd6bc007f7c2d07f6848c2eebfcc63b8eab95991751196df8"
treasury = "0x3a9902a21eabd3552edfc104cb4a6ce1ac4fe5af6aa24a56037969e1a0db3d93"
worker_peripherals = "0xb1f42e295868a61b2d78836f1199324c8964c84a54e8ff8f72c5a6594d600d07"
price_feed_router_0 = "0xe7067908019da66726a41d09dde09bc5520a91089edd4a649ed36a01b4613b67"
price_feed_router_1 = "0xbcb5f986fbffd251b26936d95d5c52761703ca1cdb3f3f3b71b5e7dd0a303813"
price_feed_module_0 = "0xa762d65f42c852e0a7f6240ec6441694ea1b4786392cdfa5351dee8364c868fc"
worker_common = "0xfe0b685e4cc9e77d91d008ef4161de68f7d7646c3bf67079fd4c2f0356631be8"
executor_fee_lib_router_0 = "0xfb62a7ea757acc3b5a5f3e19794b6a5c9f6fd56c6e3fb392aac3d9d275ea4bca"
executor_fee_lib_router_1 = "0x8824962f90a61eae9f0c2e1abaf90dac63929bb6ec0cd6c54ac1b4c9df295e29"
dvn_fee_lib_router_0 = "0x4e27bce08903acad46c4cfd35229589cc8e6975a0f9beec0e8a9aa2a1b12574b"
dvn_fee_lib_router_1 = "0x5248f0a5e6f1629e7e12dfb5d87a2b1ee3adf3f3cbf0c7a2b667053f336c985e"
executor_fee_lib_0 = "0x4123c50265067995272e998193638aaf876d75454b2aba50d55d950b2236ff4e"
dvn_fee_lib_0 = "0x9b77c6ad73d3e642f4c59ff191e1b460a7f4a16a67558edba1a744b4d6a88127"
dvn = "0x756f8ab056688d22687740f4a9aeec3b361170b28d08b719e28c4d38eed1043e"'
            ;;
        movement-testnet)
            addresses='oft_common = "0xa4c83e48703381fc23d03e3cb89088dbd363c51427fe52f352ce1668b4d146cd"
router_node_0 = "0x7a19f544a6db990a1bfa6d84d0f53f918cd41765ec5b0d67abbdb78455f1d43a"
simple_msglib = "0x98ab4d5f6f5ae0d3bc9d9785cfd63244fffc4652bf54f8971cb7035589a256eb"
blocked_msglib = "0xb79b041ff861c2ec1e67138501270d978a35bd28817565a6752bfc469fa62c06"
uln_302 = "0xcc1c03aed42e2841211865758b5efe93c0dde2cb7a2a5dc6cf25a4e33ad23690"
router_node_1 = "0x8c65dab3f69a5c35eefed1e181f68890021797156dc1842b191b2ece7bda909a"
endpoint_v2_common = "0x3bc8cbd74c2e1929c287a0063206fbb126314976146934bae12283f6120e99e9"
endpoint_v2 = "0x7f03103b83c51c8b09be1751a797a65ac6e755f72947ecdecffc203d32d816c6"
layerzero_admin = "0xb1f42e295868a61b2d78836f1199324c8964c84a54e8ff8f72c5a6594d600d07"
layerzero_treasury_admin = "0xb1f42e295868a61b2d78836f1199324c8964c84a54e8ff8f72c5a6594d600d07"
msglib_types = "0xd34d78d10b19757dd6bc007f7c2d07f6848c2eebfcc63b8eab95991751196df8"
treasury = "0x3a9902a21eabd3552edfc104cb4a6ce1ac4fe5af6aa24a56037969e1a0db3d93"
worker_peripherals = "0xb1f42e295868a61b2d78836f1199324c8964c84a54e8ff8f72c5a6594d600d07"
price_feed_router_0 = "0xe7067908019da66726a41d09dde09bc5520a91089edd4a649ed36a01b4613b67"
price_feed_router_1 = "0xbcb5f986fbffd251b26936d95d5c52761703ca1cdb3f3f3b71b5e7dd0a303813"
price_feed_module_0 = "0xa762d65f42c852e0a7f6240ec6441694ea1b4786392cdfa5351dee8364c868fc"
worker_common = "0xfe0b685e4cc9e77d91d008ef4161de68f7d7646c3bf67079fd4c2f0356631be8"
executor_fee_lib_router_0 = "0xfb62a7ea757acc3b5a5f3e19794b6a5c9f6fd56c6e3fb392aac3d9d275ea4bca"
executor_fee_lib_router_1 = "0x8824962f90a61eae9f0c2e1abaf90dac63929bb6ec0cd6c54ac1b4c9df295e29"
dvn_fee_lib_router_0 = "0x4e27bce08903acad46c4cfd35229589cc8e6975a0f9beec0e8a9aa2a1b12574b"
dvn_fee_lib_router_1 = "0x5248f0a5e6f1629e7e12dfb5d87a2b1ee3adf3f3cbf0c7a2b667053f336c985e"
executor_fee_lib_0 = "0x4123c50265067995272e998193638aaf876d75454b2aba50d55d950b2236ff4e"
dvn_fee_lib_0 = "0x9b77c6ad73d3e642f4c59ff191e1b460a7f4a16a67558edba1a744b4d6a88127"
dvn = "0x756f8ab056688d22687740f4a9aeec3b361170b28d08b719e28c4d38eed1043e"'
            ;;
        aptos-mainnet)
            addresses='oft_common = "0xcf4e1eb4b32b84266f27efe35539a9a3b7a3ec822299d8eb828ca32e581aa72c"
router_node_0 = "0x6de27e5aa7dbee0fc32af2a92b8aa0b96e0033026ade8f22e4692cd8603220e9"
simple_msglib = "0x52d5c6f8dcb20ed8ace8dbaa7cc09a98eb1dbec0f184720795310c031ace5111"
blocked_msglib = "0x3ca0d187f1938cf9776a0aa821487a650fc7bb2ab1c1d241ba319192aae4afc6"
uln_302 = "0xc33752e0220faf79e45385dd73fb28d681dcd9f1569a1480725507c1f3c3aba9"
router_node_1 = "0x2ae54c38567f217c42b255016a38ccd68b67eb276a6cc3ebad609935fe3cc70c"
endpoint_v2_common = "0xe1dc2a62b445403bea0dbd73df8cee03b3ead0a06b003e72e401c030a810a133"
endpoint_v2 = "0xe60045e20fc2c99e869c1c34a65b9291c020cd12a0d37a00a53ac1348af4f43c"
layerzero_admin = "0x19f1c63510f3ea8b8cd467ebe663897371919c185218d2859927f5a357b0bcae"
layerzero_treasury_admin = "0x19f1c63510f3ea8b8cd467ebe663897371919c185218d2859927f5a357b0bcae"
msglib_types = "0xa3fac5ed887625dd1d4371a60c7bfd5869e8ce5c3c5783fb8898dc0128365c31"
treasury = "0x77c941e60b8e2c8d784de2ee456fd497283edfe1e15704c99a192ff795fc38b7"
worker_peripherals = "0x19f1c63510f3ea8b8cd467ebe663897371919c185218d2859927f5a357b0bcae"
price_feed_router_0 = "0x969722e6e181bb17165c17492c037514cd213a0ce9830a59724190e13c011136"
price_feed_router_1 = "0x3808a699d1a14d25de813a4e0bbcde7a8ce8d27ccc9055aee8070d28172faced"
price_feed_module_0 = "0xad0f7141f626c07db99a7fe5b864fde080bc4966c144d88f6f14ac4af391f30"
worker_common = "0x1bffc83ec332cb9de738e8f0c27dd2230ee57bdbc71473047fcfe8bfaa21fab7"
executor_fee_lib_router_0 = "0xfb941d4e28fc08b94fe53c9043e392d6405a16475bccbfee5222d588cef5b709"
executor_fee_lib_router_1 = "0xf8ed27afba36de5693de4c9ea654ee73de7b0e2ac7c43a54d36bc155a944d9d1"
dvn_fee_lib_router_0 = "0x707f09a7db866c4be5d2ee7c4ffcfe38e1b893f8d757712fe224fa19da881c93"
dvn_fee_lib_router_1 = "0x31dcc84f4bfffff09648cb9ae6d84261ddb7c04646d1f2f6c38bf6d7551a0831"
executor_fee_lib_0 = "0xbbb5d80871b10c4a7c10b9bbc636fdca4faa05feb3b03dc27e3018a7bfcbd8cb"
dvn_fee_lib_0 = "0x349c43bc506cbbe7b754b164867bd1751763410b6458a798c25bb6f3c3e9e487"
dvn = "0xdf8f0a53b20f1656f998504b81259698d126523a31bdbbae45ba1e8a3078d8da"'
            ;;
        movement-mainnet)
            addresses='oft_common = "0xcf4e1eb4b32b84266f27efe35539a9a3b7a3ec822299d8eb828ca32e581aa72c"
router_node_0 = "0x6de27e5aa7dbee0fc32af2a92b8aa0b96e0033026ade8f22e4692cd8603220e9"
simple_msglib = "0x52d5c6f8dcb20ed8ace8dbaa7cc09a98eb1dbec0f184720795310c031ace5111"
blocked_msglib = "0x3ca0d187f1938cf9776a0aa821487a650fc7bb2ab1c1d241ba319192aae4afc6"
uln_302 = "0xc33752e0220faf79e45385dd73fb28d681dcd9f1569a1480725507c1f3c3aba9"
router_node_1 = "0x2ae54c38567f217c42b255016a38ccd68b67eb276a6cc3ebad609935fe3cc70c"
endpoint_v2_common = "0xe1dc2a62b445403bea0dbd73df8cee03b3ead0a06b003e72e401c030a810a133"
endpoint_v2 = "0xe60045e20fc2c99e869c1c34a65b9291c020cd12a0d37a00a53ac1348af4f43c"
layerzero_admin = "0x19f1c63510f3ea8b8cd467ebe663897371919c185218d2859927f5a357b0bcae"
layerzero_treasury_admin = "0x19f1c63510f3ea8b8cd467ebe663897371919c185218d2859927f5a357b0bcae"
msglib_types = "0xa3fac5ed887625dd1d4371a60c7bfd5869e8ce5c3c5783fb8898dc0128365c31"
treasury = "0x77c941e60b8e2c8d784de2ee456fd497283edfe1e15704c99a192ff795fc38b7"
worker_peripherals = "0x19f1c63510f3ea8b8cd467ebe663897371919c185218d2859927f5a357b0bcae"
price_feed_router_0 = "0x969722e6e181bb17165c17492c037514cd213a0ce9830a59724190e13c011136"
price_feed_router_1 = "0x3808a699d1a14d25de813a4e0bbcde7a8ce8d27ccc9055aee8070d28172faced"
price_feed_module_0 = "0xad0f7141f626c07db99a7fe5b864fde080bc4966c144d88f6f14ac4af391f30"
worker_common = "0x1bffc83ec332cb9de738e8f0c27dd2230ee57bdbc71473047fcfe8bfaa21fab7"
executor_fee_lib_router_0 = "0xfb941d4e28fc08b94fe53c9043e392d6405a16475bccbfee5222d588cef5b709"
executor_fee_lib_router_1 = "0xf8ed27afba36de5693de4c9ea654ee73de7b0e2ac7c43a54d36bc155a944d9d1"
dvn_fee_lib_router_0 = "0x707f09a7db866c4be5d2ee7c4ffcfe38e1b893f8d757712fe224fa19da881c93"
dvn_fee_lib_router_1 = "0x31dcc84f4bfffff09648cb9ae6d84261ddb7c04646d1f2f6c38bf6d7551a0831"
executor_fee_lib_0 = "0xbbb5d80871b10c4a7c10b9bbc636fdca4faa05feb3b03dc27e3018a7bfcbd8cb"
dvn_fee_lib_0 = "0x349c43bc506cbbe7b754b164867bd1751763410b6458a798c25bb6f3c3e9e487"
dvn = "0xdf8f0a53b20f1656f998504b81259698d126523a31bdbbae45ba1e8a3078d8da"'
            ;;
        *)
            echo "ERROR: unknown environment '${env}'. Expected: aptos-testnet, aptos-mainnet, movement-testnet, movement-mainnet" >&2
            return 1
            ;;
    esac

    case "$cli" in
        aptos)
            framework_dep='[dependencies.AptosFramework]
git = "https://github.com/aptos-labs/aptos-framework.git"
rev = "mainnet"
subdir = "aptos-framework"'
            ;;
        movement)
            framework_dep='[dependencies.AptosFramework]
git = "https://github.com/movementlabsxyz/aptos-core.git"
rev = "m1"
subdir = "aptos-move/framework/aptos-framework"'
            ;;
    esac

    cat > "${dir}/Move.toml" << EOF
[package]
name = "oft"
version = "1.0.0"
authors = []

[addresses]
oft = "_"
oft_admin = "_"
# ${env}
${addresses}
native_token_metadata_address = "0xa"

[dev-addresses]
oft = "0x302814823"
oft_admin = "0x12321241"
oft_common = "0x30281482332"
router_node_0 = "0x10000f"
simple_msglib = "0x100011"
blocked_msglib = "0x100001"
uln_302 = "0x100013"
router_node_1 = "0x100010"
endpoint_v2_common = "0x100007"
endpoint_v2 = "0x100006"
layerzero_admin = "0x200001"
layerzero_treasury_admin = "0x200002"
msglib_types = "0x10000b"
treasury = "0x100012"
worker_peripherals = "0x3000"
price_feed_router_0 = "0x10000d"
price_feed_router_1 = "0x10000e"
price_feed_module_0 = "0x10000c"
worker_common = "0x100014"
executor_fee_lib_router_0 = "0x100009"
executor_fee_lib_router_1 = "0x10000a"
dvn_fee_lib_router_0 = "0x100004"
dvn_fee_lib_router_1 = "0x100005"
executor_fee_lib_0 = "0x100008"
dvn_fee_lib_0 = "0x100003"
dvn = "0x100002"

${framework_dep}

[dependencies]
endpoint_v2_common = { git = "https://github.com/LayerZero-Labs/LayerZero-v2", rev = "main", subdir = "packages/layerzero-v2/aptos/contracts/endpoint_v2_common" }
endpoint_v2 = { git = "https://github.com/LayerZero-Labs/LayerZero-v2", rev = "main", subdir = "packages/layerzero-v2/aptos/contracts/endpoint_v2" }
oft_common = { git = "https://github.com/LayerZero-Labs/LayerZero-v2", rev = "main", subdir = "packages/layerzero-v2/aptos/contracts/oapps/oft_common" }

[dev-dependencies]
simple_msglib = { git = "https://github.com/LayerZero-Labs/LayerZero-v2", rev = "main", subdir = "packages/layerzero-v2/aptos/contracts/msglib/libs/simple_msglib" }
EOF

    echo "Move.toml set to ${env} in ${dir}"
}
