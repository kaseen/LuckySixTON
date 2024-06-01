import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { Address, toNano } from '@ton/core';
import { LuckySix } from '../wrappers/LuckySix';
import '@ton/test-utils';

const packCombinationToBePlayed = (arr: Array<bigint>) => {
    let result = 0n;
    for(let i = 0; i < 6; i++){
        result = result | arr[i];
        result <<= 6n;
    }
    result >>= 6n;

    return result;
}

const unpackToCombination = (packedResult: bigint) => {
    const NUMBER_OF_DRAWS = 35;
    const BITMASK_0b111111 = 63n;
    let tmp = NUMBER_OF_DRAWS - 1;
    let result: Array<bigint> = [];
    for(let i = 0; i < NUMBER_OF_DRAWS; i++){
        result[tmp - i] = (packedResult >> (BigInt(i) * BigInt(6))) & BITMASK_0b111111;
    }

    return result;
}

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

        await luckySix.send(
            deployer.getSender(),
            { value: toNano('0.03') },
            'openRound'
        );
    });

    xit('Test PlayTicket function', async () => {
        const beforePlayingTicket = await luckySix.getLastPlayedTicket(Address.parse('EQBGhqLAZseEqRXz4ByFPTGV7SVMlI4hrbs-Sps_Xzx01x8G'));
        expect(beforePlayingTicket?.packedCombination).toEqual(0n);

        const packedCombination = packCombinationToBePlayed([1n, 2n, 3n, 4n, 5n, 6n]);

        const firstTx = await luckySix.send(
            deployer.getSender(),
            { value: toNano('0.03') },
            { $$type: 'PlayTicket', packedCombination }
        );

        const afterPlayingTicket = await luckySix.getLastPlayedTicket(Address.parse('EQBGhqLAZseEqRXz4ByFPTGV7SVMlI4hrbs-Sps_Xzx01x8G'));
        expect(afterPlayingTicket?.packedCombination).toEqual(packedCombination);

        console.log('==================TODO')
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

    it('Should test if the order logic of lottery states is correct', async () => {
        const packedCombination = packCombinationToBePlayed([34n, 2n, 39n, 23n, 30n, 45n]);

        await luckySix.send(
            deployer.getSender(),
            { value: toNano('0.03') },
            { $$type: 'PlayTicket', packedCombination }
        );

        await luckySix.send(
            deployer.getSender(),
            { value: toNano('100') },
            'drawNumbers'
        );

        await luckySix.send(
            deployer.getSender(),
            { value: toNano('100') },
            'openRound'
        );

        await luckySix.send(
            deployer.getSender(),
            { value: toNano('0.03') },
            { $$type: 'PlayTicket', packedCombination }
        );

        await luckySix.send(
            deployer.getSender(),
            { value: toNano('100') },
            'drawNumbers'
        );

        console.log(await luckySix.getUnpackedDrawnNumbersForRound(0n));
        console.log(await luckySix.getUnpackedDrawnNumbersForRound(1n));
    });
});