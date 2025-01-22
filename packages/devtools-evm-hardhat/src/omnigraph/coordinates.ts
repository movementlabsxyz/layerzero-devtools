import { formatEid, type OmniPoint, nonEvmAddress } from '@layerzerolabs/devtools'
import pMemoize from 'p-memoize'
import { OmniContract } from '@layerzerolabs/devtools-evm'
import { Contract } from '@ethersproject/contracts'
import assert from 'assert'
import { OmniContractFactoryHardhat, OmniDeployment } from './types'
import { createGetHreByEid } from '@/runtime'
import { assertHardhatDeploy } from '@/internal/assertions'
import { createModuleLogger, importDefault } from '@layerzerolabs/io-devtools'
import { endpointIdToChainType, ChainType } from '@layerzerolabs/lz-definitions'

export const omniDeploymentToPoint = ({ eid, deployment }: OmniDeployment): OmniPoint => ({
    eid,
    address: deployment.address,
})

export const omniDeploymentToContract = ({ eid, deployment }: OmniDeployment): OmniContract => ({
    eid,
    contract: new Contract(deployment.address, deployment.abi),
})

export const createContractFactory = (environmentFactory = createGetHreByEid()): OmniContractFactoryHardhat => {
    return pMemoize(async ({ eid, address, contractName }) => {
        const env = await environmentFactory(eid)
        assertHardhatDeploy(env)

        const networkLabel = `${formatEid(eid)} (${env.network.name})`
        const logger = createModuleLogger(`Contract factory @ ${networkLabel}`)
        // If we have both the contract name & address, we go off artifacts
        // @Shankar: Artifacts are only available for EVM
        if (endpointIdToChainType(eid) === ChainType.EVM && contractName != null && address != null) {
            logger.verbose(`Looking for contract ${contractName} on address ${address} in artifacts`)

            const artifact = await env.deployments.getArtifact(contractName).catch((error) => {
                logger.verbose(`Failed to load artifact for contract ${contractName} on address ${address}: ${error}`)
                logger.verbose(`Will search for the contract by its address only`)
            })

            if (artifact != null) {
                const contract = new Contract(address, artifact.abi)

                return { eid, contract }
            }
        }

        // If we have the contract name but no address, we need to get it from the deployments by name
        /*
         * @Shankar: This mode lets us grab deployments from deployment files - we follow the same pattern for all vms
         *
         * @Shankar: We'll need to add support for non-EVM chains here, the default implementation is for EVM as the returned object expects ethers.Contract
         * We work around this by creating a blank contract for non-EVM chains with the address (0x0....0dead) with abi ([])
         */
        if (contractName != null && address == null) {
            logger.verbose(`Looking for contract ${contractName} in deployments`)
            const networkName = env.deployments.getNetworkName()

            const currentDir = process.cwd()
            let baseAddress: string

            let omniContract: OmniContract
            const deployment = (await importDefault(
                `${currentDir}/deployments/${networkName}/${contractName}.json`
            )) as { oftStore: string; address: string; abi: string[] }

            if (!deployment) {
                throw new Error(`Could not find a deployment for contract '${contractName}' on ${networkLabel}`)
            }

            switch (endpointIdToChainType(eid)) {
                case ChainType.SOLANA: {
                    baseAddress = deployment.address
                    const blankContract = new Contract(nonEvmAddress(), [])
                    omniContract = { eid, address: baseAddress, contract: blankContract }
                    break
                }
                case ChainType.APTOS: {
                    baseAddress = deployment.address
                    const blankContract = new Contract(nonEvmAddress(), [])
                    omniContract = { eid, address: baseAddress, contract: blankContract }
                    break
                }
                case ChainType.EVM: {
                    const evmContract = new Contract(deployment.address, deployment.abi)
                    omniContract = { eid, address: deployment.address, contract: evmContract }
                    break
                }
                default:
                    throw new Error('Unsupported chain type')
            }

            return omniContract
        }

        // And if we only have the address, we need to go get it from deployments by address
        if (address != null) {
            logger.verbose(`Looking for contract with address ${address} in deployments`)

            // The deployments can contain multiple deployment files for the same address
            //
            // This happens (besides of course a case of switching RPC URLs without changing network names)
            // when using proxies - hardhat-deploy will create multiple deployment files
            // with complete and partial ABIs
            //
            // To handle this case we'll merge the ABIs to make sure we have all the methods available
            const deployments = await env.deployments
                .getDeploymentsFromAddress(address)
                .then(
                    (deployments) =>
                        (
                            // We want to handle a case in which no deployments are returned
                            // because the store has been cleared
                            assert(
                                deployments.length > 0,
                                `Could not find a deployment for address '${address}' on ${networkLabel}`
                            ),
                            deployments
                        )
                )
                .catch(async () => {
                    // Hardhat deploy does not call its setup function when we call getDeploymentsFromAddress
                    // so we need to force it to do so
                    //
                    // Since the setup function is not available on the deployments extension, we need to trigger it indirectly
                    await env.deployments.all()

                    return await env.deployments.getDeploymentsFromAddress(address)
                })
            assert(deployments.length > 0, `Could not find a deployment for address '${address}' on ${networkLabel}`)

            const mergedAbis = deployments.flatMap((deployment) => deployment.abi)

            // Even though duplicated fragments don't throw errors, they still pollute the interface with warning console.logs
            // To prevent this, we'll run a simple deduplication algorithm - use JSON encoded values as hashes
            const deduplicatedAbi = Object.values(
                Object.fromEntries(mergedAbis.map((abi) => [JSON.stringify(abi), abi]))
            )

            return { eid, contract: new Contract(address, deduplicatedAbi) }
        }

        assert(false, `At least one of contractName, address must be specified for OmniPointHardhat on ${networkLabel}`)
    })
}
