require('dotenv').config();

const { mnemonicToWalletKey } = require('@ton/crypto');
const { WalletContractV4, TonClient, internal } = require('@ton/ton');

const CONTRACT_ADDRESS = 'EQCv9oMOPknyWSbUeqpNMFZdYxmrl871kKroUJzmuGW0GXPN';

(async () => {
    const key = await mnemonicToWalletKey(process.env.MNEMONIC.split(' '));
    const wallet = WalletContractV4.create({ publicKey: key.publicKey, workchain: 0 });

    //const endpoint = await getHttpEndpoint({ network: "testnet" });
    //const client = new TonClient({ endpoint });

    const client = new TonClient({
        endpoint: 'https://testnet.toncenter.com/api/v2/jsonRPC',
        apiKey: process.env.TONCENTER_API_KEY
    })

    if(!await client.isContractDeployed(wallet.address)) {
        return console.log("wallet is not deployed");
    }

    const walletContract = client.open(wallet);
    const seqno = await walletContract.getSeqno();
    // TODO:
    /*await walletContract.sendTransfer({
        secretKey: key.secretKey,
        seqno: seqno,
        messages: [
            internal({
                to: CONTRACT_ADDRESS,
                value: '0.05',
            })
        ]
    });*/
})();