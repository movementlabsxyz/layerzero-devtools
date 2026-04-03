# #!/bin/sh

# # Exit on any error
set -e
# Exit on undefined variables
set -u
# Exit on pipe failures
set -o pipefail

# Must match propose.sh exactly so the rebuilt payload hashes to the same value as on-chain.
multisig_address="0x98ebb7985c84a89972022edf391bdaa7d95f061d9742efb3703de368413431e1"
oft_fa="0x3dfe1ac4574c7dbbe6f1c5ba862de88fc3e7d3cf8eba95ef1abf32b582889e6d"

source ./set_move_env.sh
set_move_env movement mainnet oft-aptos-move

payload_file="$(mktemp /tmp/oft_fa_upgrade_payload.XXXX.json)"

movement move build-publish-payload \
	--package-dir oft-aptos-move \
	--named-addresses oft="$oft_fa",oft_admin="$multisig_address" \
	--json-output-file "$payload_file" \
	--assume-yes

# Hash-only proposals: use execute-with-payload (not `multisig execute`).
# Optional: simulate first with --local
movement multisig execute-with-payload \
	--multisig-address "$multisig_address" \
	--json-file "$payload_file" \
	--profile ops

rm -f "$payload_file"

# Optional: verify payload matches a pending proposal before submitting (needs sequence number).
# movement multisig verify-proposal \
# 	--multisig-address "$multisig_address" \
# 	--sequence-number <N> \
# 	--json-file "$payload_file" \
# 	--profile ops
