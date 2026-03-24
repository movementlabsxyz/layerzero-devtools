module_address="${1:-}"
admin="${2:-}"
eid="${3:-40101}"
peer="${4:-}"
cli=${5:-"movement"}
network=${6:-"mainnet"}
profile=${7:-"default"}

echo "Using CLI: $cli"
echo "Using Network: $network"
echo "Module Address: $module_address"
echo "Admin: $admin"
echo "EID: $eid"
echo "Peer: $peer"

multisig=false
multisig_address=""

# ── Set these per deployment ─────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────────────────────

if $multisig; then
	if [ -z "$multisig_address" ]; then
		echo "Error: multisig_address must be set if multisig is true"
		exit 1
	fi
	command="multisig create_transaction --multisig-address $multisig_address"
else
	command="move run"
fi

deployer=$(awk '/^  '$profile':/{flag=1} flag && /^    account:/{print $2; exit}' .$cli/config.yaml)
[[ "$deployer" != 0x* ]] && deployer="0x${deployer}"
if [ -z "$module_address" ]; then
	module_address="$deployer"
fi
[[ "$module_address" != 0x* ]] && module_address="0x${module_address}"
[[ -n "$multisig_address" && "$multisig_address" != 0x* ]] && multisig_address="0x${multisig_address}"
[[ -n "$peer" && "$peer" != 0x* ]] && peer="0x${peer}"
[[ -n "$admin" && "$admin" != 0x* ]] && admin="0x${admin}"

case "${cli}:${network}" in
	movement:testnet)
		msg_lib=0xcc1c03aed42e2841211865758b5efe93c0dde2cb7a2a5dc6cf25a4e33ad23690
		executor=0x93353700091200ef9fdc536ce6a86182cc7e62da25f94356be9421c6310b9585
		endpoint=0x7f03103b83c51c8b09be1751a797a65ac6e755f72947ecdecffc203d32d816c6
		required_dvns="0x5b983a8faf6977f0bc76ed2a96fda5abdacaeb829841c2d4da176acd78d19d97,0x5e621608b81aa5243d193bf69438c9402712303490d5d974f06f63c154fd977b,0x756f8ab056688d22687740f4a9aeec3b361170b28d08b719e28c4d38eed1043e"
		;;
	movement:mainnet)
		msg_lib=0xc33752e0220faf79e45385dd73fb28d681dcd9f1569a1480725507c1f3c3aba9
		executor=0x15a5bbf1eb7998a22c9f23810d424abe40bd59ddd8e6ab7e59529853ebed41c4
		endpoint=0xe60045e20fc2c99e869c1c34a65b9291c020cd12a0d37a00a53ac1348af4f43c
		required_dvns="0x2b696b3ee859b7eb624e1fd5de49f4d3806f49862f1177d6827fd1beffde9179,0xdf8f0a53b20f1656f998504b81259698d126523a31bdbbae45ba1e8a3078d8da,0xbcfb6d3ce5e99275e5fa09b3f53eaaea32365c776d023c51a680c4c420d88b91"
		;;
	aptos:testnet)
		msg_lib=0xcc1c03aed42e2841211865758b5efe93c0dde2cb7a2a5dc6cf25a4e33ad23690
		executor=0x93353700091200ef9fdc536ce6a86182cc7e62da25f94356be9421c6310b9585
		endpoint=0x7f03103b83c51c8b09be1751a797a65ac6e755f72947ecdecffc203d32d816c6
		required_dvns="0x5e621608b81aa5243d193bf69438c9402712303490d5d974f06f63c154fd977b,0x756f8ab056688d22687740f4a9aeec3b361170b28d08b719e28c4d38eed1043e,0x5b983a8faf6977f0bc76ed2a96fda5abdacaeb829841c2d4da176acd78d19d97"
		;;
	aptos:mainnet)
		msg_lib=0xc33752e0220faf79e45385dd73fb28d681dcd9f1569a1480725507c1f3c3aba9
		executor=0x15a5bbf1eb7998a22c9f23810d424abe40bd59ddd8e6ab7e59529853ebed41c4
		endpoint=0xe60045e20fc2c99e869c1c34a65b9291c020cd12a0d37a00a53ac1348af4f43c
		required_dvns="0x9880ed7ade7e7f8f8eb070ce72c51b231921e29e65b3d51fa3810814bba32c00,0xf3f0a412626edba5ddd3613d91109b241893873ac5479ade231cf0b3130572b5,0xcb2ab3c2fb799c6578b9950f9db7ff555a2d4967ef15437230346f56599801ae"
		;;
	*)
		echo "Error: unknown cli/network combination '${cli}:${network}'. Use cli=movement|aptos and network=testnet|mainnet."
		exit 1
		;;
esac

enforced_options="0x00030100110100000000000000000000000000013880"
optional_dvns=""
use_default_dvns=false
use_default_confirmations=false
use_default_optional_dvns=false
send_confirmations=10
receive_confirmations=10
max_message_length=10000

source ./encode_configs.sh
read -r executor_config send_config receive_config <<<"$(encode_lz_configs \
	$use_default_confirmations $send_confirmations $receive_confirmations \
	$use_default_dvns $use_default_optional_dvns \
	"$required_dvns" "$optional_dvns" \
	$executor $max_message_length $msg_lib)"

echo "Executor Config: $executor_config"
echo "Send Config: $send_config"
echo "Receive Config: $receive_config"

echo yes | $cli $command \
	--function-id "$module_address::oapp_core::set_delegate" \
	--args address:$deployer \
	--profile $profile

echo yes | $cli $command \
	--function-id "$module_address::oapp_core::set_enforced_options" \
	--args u32:$eid u16:1 hex:$enforced_options \
	--profile $profile

echo yes | $cli $command \
	--function-id "$module_address::oapp_core::set_enforced_options" \
	--args u32:$eid u16:2 hex:$enforced_options \
	--profile $profile

echo yes | $cli $command \
	--function-id "$module_address::oapp_core::set_send_library" \
	--args u32:$eid address:$msg_lib \
	--profile $profile

echo yes | $cli $command \
	--function-id "$module_address::oapp_core::set_receive_library" \
	--args u32:$eid address:$msg_lib u64:0 \
	--profile $profile

echo yes | $cli $command \
	--function-id "$module_address::oapp_core::set_config" \
	--args address:$msg_lib u32:$eid u32:1 hex:$executor_config \
	--profile $profile

echo yes | $cli $command \
	--function-id "$module_address::oapp_core::set_config" \
	--args address:$msg_lib u32:$eid u32:2 hex:$send_config \
	--profile $profile

echo yes | $cli $command \
	--function-id "$module_address::oapp_core::set_config" \
	--args address:$msg_lib u32:$eid u32:3 hex:$receive_config \
	--profile $profile

echo yes | $cli $command \
	--function-id "$module_address::oapp_core::set_peer" \
	--args u32:$eid hex:$peer \
	--profile $profile
