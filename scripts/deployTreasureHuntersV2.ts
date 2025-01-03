import { toNano } from '@ton/core';
import { TreasureHuntersV2 } from '../wrappers/TreasureHuntersV2';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const treasureHuntersV2 = provider.open(await TreasureHuntersV2.fromInit());

    await treasureHuntersV2.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(treasureHuntersV2.address);

    // run methods on `treasureHuntersV2`
}
