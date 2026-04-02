# #!/bin/sh

# # Exit on any error
set -e
# Exit on undefined variables
set -u
# Exit on pipe failures
set -o pipefail
source ./set_move_env.sh
set_move_env movement mainnet oft-aptos-move
multisig_address="0x98ebb7985c84a89972022edf391bdaa7d95f061d9742efb3703de368413431e1"

movement multisig create-transaction \
	--multisig-address "$multisig_address" \
  --function-id 0xb52bac12e50458cd2b958b82b05e3a240834eefbfc4b1bc0729fd580c625f1ea::liquid_staking::stake_and_mint \
  --args u64:1000000000000000 \
  --profile ops