import { NetworkProvider } from '@ton/blueprint';
import { toNano } from '@ton/core';
import { TreasureHunters } from '../wrappers/TreasureHunters';

export async function run(provider: NetworkProvider) {
    const treasureHuntersV2 = provider.open(await TreasureHunters.fromInit({ $$type: 'Config', numberOfPlayers: 6n, ticketPrice: toNano("0.1"), treasurePercent: 70n, referrerBonusPercent: 5n }));

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
