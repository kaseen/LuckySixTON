import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { Address, toNano, fromNano } from '@ton/core';
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

const LOTTERY_READY = 0n;
const LOTTERY_STARTED = 1n;
const LOTTERY_CLOSED = 2n;

describe('LuckySix', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let user: SandboxContract<TreasuryContract>;
    let luckySix: SandboxContract<LuckySix>;

    let deployerAddress: Address;
    let userAddress: Address;

    beforeEach(async () => {
        blockchain = await Blockchain.create();
        luckySix = blockchain.openContract(await LuckySix.fromInit());

        deployer = await blockchain.treasury('deployer');
        deployerAddress = deployer.address;

        user = await blockchain.treasury('user');
        userAddress = user.address;

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

        expect(await luckySix.getLotteryState()).toEqual(LOTTERY_READY);

        const packedCombination = packCombinationToBePlayed([1n, 2n, 3n, 4n, 5n, 6n]);
        await luckySix.send(
            deployer.getSender(),
            { value: toNano('100') },
            { $$type: 'PlayTicket', packedCombination }
        );
    });

    xit('Should test if the order logic of lottery states is correct', async () => {
        const packedCombination = packCombinationToBePlayed([1n, 2n, 3n, 4n, 5n, 6n]);

        await luckySix.send(
            deployer.getSender(),
            { value: toNano('1') },
            { $$type: 'PlayTicket', packedCombination }
        );
        expect(await luckySix.getLotteryState()).toEqual(LOTTERY_STARTED);

        await luckySix.send(
            deployer.getSender(),
            { value: toNano('100') },
            'drawNumbers'
        );
        expect(await luckySix.getLotteryState()).toEqual(LOTTERY_CLOSED);

        await luckySix.send(
            deployer.getSender(),
            { value: toNano('100') },
            'openRound'
        );
        expect(await luckySix.getLotteryState()).toEqual(LOTTERY_READY);

        await luckySix.send(
            deployer.getSender(),
            { value: toNano('1') },
            { $$type: 'PlayTicket', packedCombination }
        );
        expect(await luckySix.getLotteryState()).toEqual(LOTTERY_STARTED);

        await luckySix.send(
            deployer.getSender(),
            { value: toNano('100') },
            'drawNumbers'
        );
        expect(await luckySix.getLotteryState()).toEqual(LOTTERY_CLOSED);

        console.log(await luckySix.getUnpackedDrawnNumbersForRound(0n));
        console.log(await luckySix.getUnpackedDrawnNumbersForRound(1n));
    });

    it('Should correctly play two different tickets in two different rounds', async () => {
        const beforePlayingTicket = await luckySix.getLastPlayedTicket(userAddress);
        expect(beforePlayingTicket?.packedCombination).toEqual(0n);

        const packedCombination = packCombinationToBePlayed([45n, 23n, 12n, 11n, 37n, 1n]);

        console.log(fromNano(await luckySix.getLotteryBalance()));

        await luckySix.send(
            user.getSender(),
            { value: toNano('1') },
            { $$type: 'PlayTicket', packedCombination }
        );
        expect(await luckySix.getLotteryState()).toEqual(LOTTERY_STARTED);

        const afterPlayingTicket = await luckySix.getLastPlayedTicket(userAddress);
        expect(afterPlayingTicket?.packedCombination).toEqual(packedCombination);

        console.log(afterPlayingTicket)

        await luckySix.send(
            deployer.getSender(),
            { value: toNano('10') },
            'drawNumbers'
        );
        expect(await luckySix.getLotteryState()).toEqual(LOTTERY_CLOSED);

        console.log(fromNano(await user.getBalance()));
        await luckySix.send(
            user.getSender(),
            { value: toNano('1') },
            'resolveTicketStatus'
        )
        console.log(fromNano(await user.getBalance()));

        console.log(await luckySix.getLastPlayedTicket(userAddress));

        //console.log(await luckySix.getUnpackedDrawnNumbersForRound(0n));
    });
});
