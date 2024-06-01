import { toNano } from '@ton/core';
import { LuckySix } from '../wrappers/LuckySix';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const luckySix = provider.open(await LuckySix.fromInit());

    await luckySix.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(luckySix.address);

    // run methods on `luckySix`
}
