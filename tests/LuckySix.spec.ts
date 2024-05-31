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

    it('should work', async () => {
        const before = await luckySix.getLastPlayedTicket(Address.parse('EQBGhqLAZseEqRXz4ByFPTGV7SVMlI4hrbs-Sps_Xzx01x8G'));
        console.log(before);

        const packedCombination = 69n;

        await luckySix.send(
            deployer.getSender(),
            { value: toNano('0.03') },
            { $$type: 'PlayTicket', packedCombination }
        );

        const after = await luckySix.getLastPlayedTicket(Address.parse('EQBGhqLAZseEqRXz4ByFPTGV7SVMlI4hrbs-Sps_Xzx01x8G'));
        console.log(after);
    });
});
