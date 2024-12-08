import { AptosOFTMetadata, ContractMetadataMapping, EidTxMap } from '../utils/types'
import { diffPrinter } from '../utils/utils'
import { Contract, utils } from 'ethers'

/**
 * Sets peer information for connections to wire.
 */
export async function createSetDelegateTransactions(
    eidDataMapping: ContractMetadataMapping,
    _aptosOft: AptosOFTMetadata
): Promise<EidTxMap> {
    const txTypePool: EidTxMap = {}

    for (const [eid, { address, contract, configAccount }] of Object.entries(eidDataMapping)) {
        const fromDelegate = await getDelegate(contract.epv2, address.oapp)

        if (configAccount?.delegate === undefined) {
            console.log(`\x1b[43m Skipping: No delegate has been set for ${eid} @ ${address.oapp} \x1b[0m`)
            continue
        }

        const toDelegate = utils.getAddress(configAccount.delegate)

        if (fromDelegate === toDelegate) {
            console.log(`\x1b[43m Skipping: The same delegate has been set for ${eid} @ ${address.oapp} \x1b[0m`)
            continue
        }

        diffPrinter(`Setting Delegate on ${eid}`, { delegate: fromDelegate }, { delegate: toDelegate })

        const tx = await contract.oapp.populateTransaction.setDelegate(toDelegate)

        if (!txTypePool[eid]) {
            txTypePool[eid] = []
        }

        txTypePool[eid].push(tx)
    }

    return txTypePool
}

export async function getDelegate(epv2Contract: Contract, oappAddress: string) {
    const delegate = await epv2Contract.delegates(oappAddress)
    const delegateAddress = utils.getAddress(delegate)

    return delegateAddress
}
