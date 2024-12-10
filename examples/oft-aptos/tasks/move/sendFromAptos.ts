import { Aptos, AptosConfig } from '@aptos-labs/ts-sdk'
import { OFT } from '../../sdk/oft'
import { getAptosOftAddress, sendAllTxs } from './utils/utils'
import { getLzNetworkStage, parseYaml } from './utils/aptosNetworkParser'
import { EndpointId } from '@layerzerolabs/lz-definitions-v3'
import { hexAddrToAptosBytesAddr } from '../../sdk/utils'

async function main() {
    const { account_address, private_key, network } = await parseYaml()
    console.log(`Using aptos network ${network}`)

    const aptosConfig = new AptosConfig({ network: network })
    const aptos = new Aptos(aptosConfig)

    const lzNetworkStage = getLzNetworkStage(network)
    const aptosOftAddress = getAptosOftAddress(lzNetworkStage)

    const oft = new OFT(aptos, aptosOftAddress, account_address, private_key)

    const amount_ld = 1
    const min_amount_ld = 1

    console.log(`Attempting to send ${amount_ld} units`)
    console.log(`Using OFT address: ${aptosOftAddress}`)
    console.log(`From account: ${account_address}`)

    const dst_eid = EndpointId.BSC_V2_TESTNET
    const to = hexAddrToAptosBytesAddr('0x0000000000000000000000003e96158286f348145819244000776202ae5e0283')
    const extra_options = new Uint8Array([])
    const compose_message = new Uint8Array([])
    const oft_cmd = new Uint8Array([])

    const [nativeFee, zroFee] = await oft.quoteSend(
        account_address,
        dst_eid,
        to,
        amount_ld,
        min_amount_ld,
        extra_options,
        compose_message,
        oft_cmd,
        false // pay_in_zro: false to pay in native tokens
    )

    console.log('\nQuote received:')
    console.log('- Native fee:', nativeFee)
    console.log('- ZRO fee:', zroFee)

    const sendPayload = oft.sendPayload(
        dst_eid,
        to,
        amount_ld,
        min_amount_ld,
        extra_options,
        compose_message,
        oft_cmd,
        nativeFee,
        0
    )

    await sendAllTxs(aptos, oft, account_address, [sendPayload])

    // Check the balance again
    const balance = await aptos.view({
        payload: {
            function: `${aptosOftAddress}::oft::balance`,
            functionArguments: [account_address],
        },
    })
    console.log('New balance:', balance)
}

main().catch((error) => {
    console.error('Error:', error)
    process.exit(1)
})
