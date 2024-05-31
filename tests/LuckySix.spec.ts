import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { Address, toNano } from '@ton/core';
import { LuckySix } from '../wrappers/LuckySix';
import '@ton/test-utils';

describe('LuckySix', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let luckySix: SandboxContract<LuckySix>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        luckySix = blockchain.openContract(await LuckySix.fromInit());

        deployer = await blockchain.treasury('deployer');

        const deployResult = await luckySix.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            }
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: luckySix.address,
            deploy: true,
            success: true,
        });
    });

    it('Test PlayTicket function', async () => {
        const beforePlayingTicket = await luckySix.getLastPlayedTicket(Address.parse('EQBGhqLAZseEqRXz4ByFPTGV7SVMlI4hrbs-Sps_Xzx01x8G'));
        expect(beforePlayingTicket?.packedTicketCombination).toEqual(0n);

        const packedCombination = 123n;

        const firstTx = await luckySix.send(
            deployer.getSender(),
            { value: toNano('0.03') },
            { $$type: 'PlayTicket', packedCombination }
        );

        const afterPlayingTicket = await luckySix.getLastPlayedTicket(Address.parse('EQBGhqLAZseEqRXz4ByFPTGV7SVMlI4hrbs-Sps_Xzx01x8G'));
        expect(afterPlayingTicket?.packedTicketCombination).toEqual(123n);

        const secondTx = await luckySix.send(
            deployer.getSender(),
            { value: toNano('0.03') },
            { $$type: 'PlayTicket', packedCombination }
        );

        /*
        TODO
        expect(secondTx.transactions).toHaveTransaction({
            exitCode: 1234444
        })*/

    });

    it('Sould unpack', async () => {
        // 000110 000101 000100 000011 000010 000001 = 6527398017n
        const bla = await luckySix.getBla(6527398017n);
        
        console.log(bla);
    });
});
