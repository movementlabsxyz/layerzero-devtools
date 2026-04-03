# #!/bin/sh

# Execute a hash-only multisig proposal for object_code_deployment::upgrade. Rebuild must match propose_object_upgrade.sh
# (same oft_fa, named-addresses, package, and jq transform) or the hash will not match.
#
# Requires: jq (brew install jq)
#
set -e
set -u
set -o pipefail

if ! command -v jq >/dev/null 2>&1; then
	echo "jq is required (e.g. brew install jq)" >&2
	exit 1
fi

multisig_address="0x98ebb7985c84a89972022edf391bdaa7d95f061d9742efb3703de368413431e1"
oft_fa="0x3dfe1ac4574c7dbbe6f1c5ba862de88fc3e7d3cf8eba95ef1abf32b582889e6d"

source ./set_move_env.sh
set_move_env movement mainnet oft-aptos-move

base_payload="$(mktemp /tmp/oft_object_upgrade_base.XXXXXX.json)"
payload_file="$(mktemp /tmp/oft_object_upgrade_payload.XXXXXX.json)"

cleanup() {
	rm -f "$base_payload" "$payload_file"
}
trap cleanup EXIT

movement move build-publish-payload \
	--package-dir oft-aptos-move \
	--named-addresses oft="$oft_fa",oft_admin="$multisig_address" \
	--json-output-file "$base_payload" \
	--assume-yes

jq --arg obj "$oft_fa" \
	'.function_id = "0x1::object_code_deployment::upgrade" | .args += [{"type": "address", "value": $obj}]' \
	"$base_payload" >"$payload_file"

# Simulate first: append --local. Remove --assume-yes to review gas prompts interactively.
movement multisig execute-with-payload \
	--multisig-address "$multisig_address" \
	--json-file "$payload_file" \
	--assume-yes \
	--profile eoa

# movement multisig verify-proposal \
# 	--multisig-address "$multisig_address" \
# 	--sequence-number <N> \
# 	--json-file "$payload_file" \
# 	--profile ops
