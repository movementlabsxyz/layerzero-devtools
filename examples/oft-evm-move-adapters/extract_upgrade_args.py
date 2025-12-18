#!/usr/bin/env python3
"""
Script to extract upgrade arguments from Move build artifacts.
This converts the compiled bytecode and metadata to the format needed for the first two args in object_code_deployment::upgrade

The third arg is 0x7e4fd97ef92302eea9b10f74be1d96fb1f1511cf7ed28867b0144ca89c6ebc3c (the object address never changes)
First, in Move.toml change the [addresses] section to

[addresses]
oft = "0x7e4fd97ef92302eea9b10f74be1d96fb1f1511cf7ed28867b0144ca89c6ebc3c"
oft_admin = "0xd38fc33916098866c4f18e6c80e75dd6b5af0d397acd063214bf3e78673ce25f"
oft_common = "0xcf4e1eb4b32b84266f27efe35539a9a3b7a3ec822299d8eb828ca32e581aa72c"
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
dvn = "0xdf8f0a53b20f1656f998504b81259698d126523a31bdbbae45ba1e8a3078d8da"
native_token_metadata_address = "0xa"
# For Initia: "0x8e4733bdabcf7d4afc3d14f0dd46c9bf52fb0fce9e4b996c939e195b8bc891d9"

and delete [dev-addresses] section.

Then compile with 

movement move compile --save-metadata

Finally, run the script to extract the upgrade arguments:

python3 extract_upgrade_args.py

Output:
    - metadata_serialized: vector<u8> from package-metadata.bcs
    - code: vector<vector<u8>> from module .mv files    
"""

from pathlib import Path

def read_file_as_decimal_array(filepath):
    """Read a file and return its contents as a decimal u8 array string."""
    with open(filepath, 'rb') as f:
        bytes_data = f.read()
    # Format as decimal array: [161, 28, 235, ...]
    decimal_array = ', '.join(str(b) for b in bytes_data)
    return f"[{decimal_array}]", len(bytes_data), list(bytes_data)

def main():
    # Path to build directory
    build_dir = Path("build/oft")

    # 1. Read package-metadata.bcs
    metadata_path = build_dir / "package-metadata.bcs"
    if not metadata_path.exists():
        print(f"Error: {metadata_path} not found!")
        return

    print("=" * 80)
    print("METADATA_SERIALIZED (vector<u8>)")
    print("=" * 80)
    metadata_decimal, metadata_size, metadata_bytes = read_file_as_decimal_array(metadata_path)
    print()

    # Save to file for easier copying
    with open("metadata_arg.txt", "w") as f:
        f.write(metadata_decimal)
    print("✓ Saved to metadata_arg.txt\n")

    # 2. Read all module bytecode files (only your modules, not dependencies)
    # IMPORTANT: Modules must be in dependency order, not alphabetical order!
    # The order matches the build output from `movement move compile --save-metadata`
    module_order = [
        "oapp_store.mv",
        "oft_store.mv",
        "oft_core.mv",
        "oapp_core.mv",
        "oft_impl_config.mv",
        "move_oft_adapter.mv",
        "oft.mv",
        "oapp_compose.mv",
        "oapp_receive.mv",
    ]

    bytecode_dir = build_dir / "bytecode_modules"
    module_files = [bytecode_dir / name for name in module_order]

    # Verify all files exist
    missing = [f for f in module_files if not f.exists()]
    if missing:
        print(f"Error: Missing module files: {missing}")
        return

    print("=" * 80)
    print("CODE (vector<vector<u8>>)")
    print("=" * 80)
    print(f"Found {len(module_files)} modules (in dependency order):\n")

    code_vectors = []
    code_bytes_list = []
    for module_file in module_files:
        module_decimal, module_size, module_bytes = read_file_as_decimal_array(module_file)
        print(f"  - {module_file.name}")
        code_vectors.append(module_decimal)
        code_bytes_list.append(module_bytes)

    # Format as vector<vector<u8>>
    code_arg = "[\n  " + ",\n  ".join(code_vectors) + "\n]"

    print()

    # Save to file
    with open("code_arg.txt", "w") as f:
        f.write(code_arg)
    print("✓ Saved to code_arg.txt")
    print()

if __name__ == "__main__":
    main()
