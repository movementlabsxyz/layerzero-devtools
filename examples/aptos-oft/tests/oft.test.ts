import { EndpointId } from '@layerzerolabs/lz-definitions'
import { Aptos, AptosConfig, Network } from '@aptos-labs/ts-sdk'
import { OFT } from '../sdk/oft'
import { encodeAddress } from '../sdk/utils'
import { Options } from '@layerzerolabs/lz-v2-utilities'

const account_address = '0x3d24005f22a2913a9e228547177a01a817fcd5bbaa5290b07fe4826f3f31be4a'
const OFT_ADDRESS = '0x7f60ccab14fa9ee93e7ff447b1bbcaed78af89e7c680c075a8bd29c5db2aca94'
const BSC_OFT_ADAPTER_ADDRESS = '0x70997970C51812dc3A010C7d01b50e0d17dc79C8'
const public_key = '0x8cea84a194ce8032cdd6e12dd87735b4f03a5ba428f3c4265813c7a39ec984d8'
const private_key = '0xc4a953452fb957eddc47e309b5679c020e09c4d3c872bda43569cbff6671dca6'

describe('oft-tests', () => {
    let aptos: Aptos
    let oft: OFT

    beforeEach(async () => {
        const config = new AptosConfig({
            network: Network.CUSTOM,
            fullnode: 'http://127.0.0.1:8080/v1',
            indexer: 'http://127.0.0.1:8090/v1',
            faucet: 'http://127.0.0.1:8081',
        })
        aptos = new Aptos(config)
        oft = new OFT(aptos, OFT_ADDRESS, account_address, private_key)
    })

    describe('delegates', () => {
        it('Should set Delegate', async () => {
            await oft.setDelegate('0x0')

            const delegate = await oft.getDelegate()

            expect(delegate).toEqual(['0x0'])
        })
    })

    describe('peer', () => {
        it('Should set peer', async () => {
            await oft.setPeer(EndpointId.BSC_TESTNET, BSC_OFT_ADAPTER_ADDRESS)

            const peer = await oft.getPeer(EndpointId.BSC_TESTNET)

            // Convert bytes array to hex string
            const peerHexString = '0x' + Buffer.from(encodeAddress(BSC_OFT_ADAPTER_ADDRESS)).toString('hex')
            expect(peer).toEqual([peerHexString])
        })
    })

    describe('enforced options', () => {
        it('Should set enforced options', async () => {
            const options = Options.newOptions().addExecutorLzReceiveOption(200000, 0).toBytes()

            await oft.setEnforcedOptions(EndpointId.BSC_TESTNET, 1, options)

            const enforcedOptions = await oft.getEnforcedOptions(EndpointId.BSC_TESTNET, 1)
            const expectedOptionsHex = '0x' + Buffer.from(options).toString('hex')
            expect(enforcedOptions).toEqual([expectedOptionsHex])
        })
    })
})
