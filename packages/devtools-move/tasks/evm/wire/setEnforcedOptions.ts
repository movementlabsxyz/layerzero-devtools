import { Contract } from 'ethers'

import {
    ComposeOption,
    ExecutorLzReceiveOption,
    ExecutorNativeDropOption,
    ExecutorOptionType,
    Options,
} from '@layerzerolabs/lz-v2-utilities'

import { diffPrinter } from '../../shared/utils'

import type { ContractMetadataMapping, EidTxMap, NonEvmOAppMetadata, enforcedOptionParam } from '../utils/types'

type optionTypes = boolean | ExecutorLzReceiveOption | ExecutorNativeDropOption | ComposeOption | undefined

/**
 * @notice Sets EnforcedOptions for a contract.
 * @dev Fetches the current enforcedOptions from Oapp
 * @dev Sets the new enforcedOptions on the Oapp
 * @returns EidTxMap
 */
export async function createSetEnforcedOptionsTransactions(
    eidDataMapping: ContractMetadataMapping,
    _nonEvmOapp: NonEvmOAppMetadata
): Promise<EidTxMap> {
    const txTypePool: EidTxMap = {}

    for (const [eid, { address, contract, configOapp }] of Object.entries(eidDataMapping)) {
        if (!configOapp?.enforcedOptions) {
            console.log(`\x1b[43m Skipping: No enforced options have been set for ${eid} @ ${address.oapp} \x1b[0m`)
            continue
        }
        const toEnforcedOptions = configOapp.enforcedOptions
        const thisEnforcedOptionBuilder: Record<number, Options> = {}

        // Iterate over toEnforcedOptions and reduce by msgType
        for (const currEnforcedOption of toEnforcedOptions) {
            if (!thisEnforcedOptionBuilder[currEnforcedOption.msgType]) {
                thisEnforcedOptionBuilder[currEnforcedOption.msgType] = Options.newOptions()
            }

            thisEnforcedOptionBuilder[currEnforcedOption.msgType] = reduceOptionsByMsgType(
                thisEnforcedOptionBuilder[currEnforcedOption.msgType],
                currEnforcedOption
            )
        }

        // Extract the msgTypes
        const msgTypes = Object.keys(thisEnforcedOptionBuilder).map((msgType) => Number(msgType))

        // Populate the arguments for the transaction function call
        const enforcedOptionParams: enforcedOptionParam[] = []

        const diffcurrOptions: Record<number, string> = {}
        const diffnewOptions: Record<number, string> = {}

        for (const msgType of msgTypes) {
            const currOptions = await getEnforcedOption(contract.oapp, eid, msgType)
            const newOptions = thisEnforcedOptionBuilder[msgType].toHex()

            if (currOptions === newOptions) {
                console.log(
                    `\x1b[43m Skipping: The same enforced options have been set for ${eid} @ ${address.oapp} \x1b[0m`
                )
            } else {
                diffcurrOptions[msgType] = currOptions
                diffnewOptions[msgType] = newOptions

                enforcedOptionParams.push({
                    eid: eid,
                    msgType: msgType,
                    options: newOptions,
                })

                const currOptionsDecoded: Record<string, optionTypes> = {}
                const newOptionsDecoded: Record<string, optionTypes> = {}
                const optionTypeCount = Object.keys(ExecutorOptionType).length / 2

                for (let i = 1; i <= optionTypeCount; i++) {
                    const currOption = decodeOptionsByMsgType(currOptions, i)
                    const newOption = decodeOptionsByMsgType(newOptions, i)

                    if (typeof currOption === 'object' && typeof newOption === 'object') {
                        const newOptionKeys = Object.keys(newOption)

                        if (newOptionKeys.length > 0) {
                            const optionTypeName = ExecutorOptionType[i]
                            currOptionsDecoded[`${optionTypeName}`] = currOption
                            newOptionsDecoded[`${optionTypeName}`] = newOption
                        }
                    }
                }

                diffPrinter(
                    `Setting Enforced Options on eid: ${eid} - msgType: ${msgType}`,
                    currOptionsDecoded,
                    newOptionsDecoded
                )

                const tx = await contract.oapp.populateTransaction.setEnforcedOptions(enforcedOptionParams)

                txTypePool[eid] = txTypePool[eid] ?? []
                txTypePool[eid].push(tx)
            }
        }
    }

    return txTypePool
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function reduceOptionsByMsgType(baseOptions: Options, addOption: any): Options {
    const optionType = addOption.optionType
    switch (optionType) {
        case ExecutorOptionType.LZ_RECEIVE:
            baseOptions.addExecutorLzReceiveOption(addOption.gas, addOption.value)
            break
        case ExecutorOptionType.NATIVE_DROP:
            baseOptions.addExecutorNativeDropOption(addOption.amount, addOption.receiver)
            break
        case ExecutorOptionType.COMPOSE:
            baseOptions.addExecutorComposeOption(Number(addOption.gas), addOption.value)
            break
        case ExecutorOptionType.ORDERED:
            baseOptions.addExecutorOrderedExecutionOption()
            break
        case ExecutorOptionType.LZ_READ:
            baseOptions.addExecutorLzReadOption(addOption.gas, addOption.value)
            break
        default:
            throw new Error(`Unknown option type: ${optionType}`)
    }

    return baseOptions
}

function decodeOptionsByMsgType(baseOption: string, msgType: number): optionTypes {
    const options = Options.fromOptions(baseOption)

    switch (msgType) {
        case ExecutorOptionType.LZ_RECEIVE:
            return options.decodeExecutorLzReceiveOption()
        case ExecutorOptionType.NATIVE_DROP:
            return options.decodeExecutorNativeDropOption()
        case ExecutorOptionType.COMPOSE:
            return options.decodeExecutorComposeOption()
        case ExecutorOptionType.ORDERED:
            return options.decodeExecutorOrderedExecutionOption()
        case ExecutorOptionType.LZ_READ:
            return options.decodeExecutorLzReadOption()
        default:
            throw new Error(`Unknown option type: ${msgType}`)
    }
}

export async function getEnforcedOption(oappContract: Contract, eid: string, msgTypes: number): Promise<string> {
    const options = await oappContract.enforcedOptions(eid, msgTypes)

    return options
}
