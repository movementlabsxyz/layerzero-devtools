# #!/bin/sh

# # Exit on any error
set -e
# Exit on undefined variables
set -u
# Exit on pipe failures
set -o pipefail
cli="aptos"
environment="mainnet"
profile="gui"
token_name="GUI"
symbol="GUI"
icon_uri="https://www.guiinu.com/favicon.svg"
project_uri="https://www.guiinu.com/"
module_name="oft_adapter_fa"
target_eid=30325
target_fa="0x0009da434d9b873b5159e8eeed70202ad22dc075867a7793234fbc981b63e119"
shared_decimals=6
peer="0xc78639b024a4c159d13f8c8a80e4fed0bd5aa62a1924c905239e3b6bcb7aa81f"
dir=""
if [ "$module_name" == "oft_fa" ] ; then
  dir="oft-aptos-move"
elif [ "$module_name" == "oft_adapter_fa" ] ; then
  dir="oft-adapter-aptos-move"
fi

source ./set_move_env.sh
set_move_env "$cli" "$environment" "$dir"

echo "Initializing $cli..."
if [ $profile == "testnet" ]; then
  echo "" | $cli init --assume-yes --network $environment --profile $profile
fi

echo "Extracting deployer address from $profile account..."
deployer=$(awk '/^  '$profile':/{flag=1} flag && /^    account:/{print $2; exit}' .$cli/config.yaml)
# Validate deployer address is not empty
if [ -z "$deployer" ]; then
  echo "Error: Failed to extract deployer address from .$cli/config.yaml"
  exit 1
fi


# config the final admin (can be the same as deployer or different)
final_admin=$deployer

echo "Publishing module..."
# publish_result=$($cli move deploy-object --address-name oft --named-addresses oft_admin=$deployer --profile $profile --assume-yes --package-dir $dir 2>&1)
# echo "Publish result: $publish_result"
# object_addr=$(echo "$publish_result" | grep -oE 'object address (0x[0-9a-fA-F]+)' | grep -oE '0x[0-9a-fA-F]+' | head -n 1 || true)
object_addr="0xc78639b024a4c159d13f8c8a80e4fed0bd5aa62a1924c905239e3b6bcb7aa81f"

if [ -z "$object_addr" ]; then
  echo "Error: Failed to extract object address from publish result"
  echo "Publish output:"
  # echo "$publish_result"
  exit 1
fi

echo "Deployer address: $deployer"
echo "Initializing $symbol..."

to_u8_vec() {
  printf "%s" "$1" \
    | od -An -t u1 \
    | tr -s '[:space:]' '\n' \
    | grep -E '^[0-9]+$' \
    | awk 'NR==1{printf "%s",$1; next} {printf ", %s",$1}'
}

token_name_u8=$(to_u8_vec "$token_name")
symbol_u8=$(to_u8_vec "$symbol")
icon_uri_u8=$(to_u8_vec "$icon_uri")
project_uri_u8=$(to_u8_vec "$project_uri")

# if [ "$module_name" == "oft_fa" ] ; then
# 	echo yes | $cli move run --function-id ${object_addr}::${module_name}::initialize \
# 	--args "u8:[$token_name_u8]" \
# 	"u8:[$symbol_u8]" \
# 	"u8:[$icon_uri_u8]" \
# 	"u8:[$project_uri_u8]" \
# 	u8:$shared_decimals \
# 	u8:$shared_decimals \
# 	--profile $profile

# elif [ "$module_name" == "oft_adapter_fa" ] ; then
# 	echo yes | $cli move run --function-id ${object_addr}::${module_name}::initialize \
# 	--args --args address:$target_fa \
# 	u8:$shared_decimals \
# 	--profile $profile
# fi


if [ "$final_admin" != "$deployer" ]; then
  movement move run --assume-yes --function-id 0x1::object::transfer_call \
	--args address:${object_addr} \
	address:${final_admin} \
	--profile $profile
fi

if [ "$peer" ]; then
  echo "Configuring $symbol with peer $peer and target EID $target_eid client $cli on network $environment..."
  bash config.sh "$object_addr" "$final_admin" "$target_eid" "$peer" "$cli" "$environment" "$profile"
fi