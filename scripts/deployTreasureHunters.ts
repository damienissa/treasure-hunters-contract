import { toNano } from '@ton/core';
import { TreasureHunters } from '../wrappers/TreasureHunters';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const treasureHunters = provider.open(await TreasureHunters.fromInit(BigInt(Math.floor(Math.random() * 10000))));

    await treasureHunters.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(treasureHunters.address);

    console.log('ID', await treasureHunters.getId());
}
