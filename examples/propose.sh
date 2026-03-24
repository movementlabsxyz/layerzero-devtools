# #!/bin/sh

# # Exit on any error
set -e
# Exit on undefined variables
set -u
# Exit on pipe failures
set -o pipefail

multisig_address="0x98ebb7985c84a89972022edf391bdaa7d95f061d9742efb3703de368413431e1"
oft_fa="0x3dfe1ac4574c7dbbe6f1c5ba862de88fc3e7d3cf8eba95ef1abf32b582889e6d"

# ---- Upgrade oft_fa module ----
source ./set_move_env.sh
set_move_env movement mainnet oft-aptos-move

payload_file="$(mktemp /tmp/oft_fa_upgrade_payload.XXXX.json)"

movement move build-publish-payload \
	--package-dir oft-aptos-move \
	--named-addresses oft="$oft_fa",oft_admin="$multisig_address" \
	--json-output-file "$payload_file" \
	--assume-yes

movement multisig create-transaction \
	--multisig-address "$multisig_address" \
	--json-file "$payload_file" \
	--store-hash-only \
	--local \
	--profile ops

rm -f "$payload_file"

# ---- Example: freeze a fungible store ----
# movement multisig create-transaction --multisig-address "$multisig_address" \
# 	--function-id 0x3dfe1ac4574c7dbbe6f1c5ba862de88fc3e7d3cf8eba95ef1abf32b582889e6d::oft_fa::set_fungible_store_frozen \
# 	--type-args 0x1::fungible_asset::FungibleStore \
# 	--args address:0x9ac6e9464dbeeeb6c430e9bdea01b3ca832335717cdc345ad3887e6aa5a446ec bool:true \
# 	--profile ops