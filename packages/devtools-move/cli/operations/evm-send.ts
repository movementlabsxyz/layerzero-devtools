import { INewOperation } from '@layerzerolabs/devtools-extensible-cli'
import { createEvmOmniContracts, readPrivateKey } from '../../tasks/evm/wire-evm'
import { ethers } from 'ethers'

class EVMQuoteSendOperation implements INewOperation {
    vm = 'evm'
    operation = 'send'
    description = 'Sends an OFT message'
    reqArgs = ['oapp_config', 'src_eid', 'dst_eid', 'to', 'amount', 'min_amount']
    addArgs = [
        {
            name: '--src-eid',
            arg: {
                help: 'The source endpoint ID',
                required: false,
            },
        },
        {
            name: '--dst-eid',
            arg: {
                help: 'The destination endpoint ID',
                required: false,
            },
        },
        {
            name: '--to',
            arg: {
                help: 'The address to send the message to',
                required: false,
            },
        },
        {
            name: '--amount',
            arg: {
                help: 'The amount to send',
                required: false,
            },
        },
        {
            name: '--min-amount',
            arg: {
                help: 'The minimum amount to send',
                required: false,
            },
        },
        {
            name: '--refund-address',
            arg: {
                help: 'The address to refund the gas fee to',
                required: false,
            },
        },
    ]

    async impl(args: any): Promise<void> {
        await sendOFT(args)
    }
}

const NewOperation = new EVMQuoteSendOperation()
export { NewOperation }

async function sendOFT(args: any): Promise<MessagingFee> {
    const srcEid = args.src_eid
    const dstEid = args.dst_eid
    const to = args.to
    const amount = args.amount
    const minAmount = args.min_amount
    const refundAddress = args.refund_address

    const privateKey = readPrivateKey(args)

    const omniContracts = await createEvmOmniContracts(args, privateKey)

    let oft: ethers.Contract
    if (omniContracts[srcEid.toString()]) {
        oft = omniContracts[srcEid.toString()].contract.oapp
    } else {
        throw new Error(`No OApp found for endpoint ID ${srcEid}`)
    }

    const sendParam: SendParam = {
        dstEid: dstEid,
        to: to,
        amountLD: amount,
        minAmountLD: minAmount,
        extraOptions: '0x',
        composeMsg: '0x',
        oftCmd: '0x',
    }

    const fee: MessagingFee = await oft.quoteSend(sendParam, false)

    const tx = await oft.send(sendParam, fee, refundAddress, {
        value: fee.nativeFee,
    })
    console.log('tx:', tx)
    return tx
}

type SendParam = {
    dstEid: number
    to: string
    amountLD: number
    minAmountLD: number
    extraOptions: string
    composeMsg: string
    oftCmd: string
}

type MessagingFee = {
    nativeFee: bigint
    lzTokenFee: bigint
}
