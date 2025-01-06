import { NetworkProvider } from '@ton/blueprint';
import { toNano } from '@ton/core';
import { TreasureHuntersV2 } from '../wrappers/TreasureHuntersV2';

export async function run(provider: NetworkProvider) {
    const treasureHuntersV2 = provider.open(await TreasureHuntersV2.fromInit({ $$type: 'Config', numberOfPlayers: 6n, ticketPrice: toNano("0.1"), treasurePercent: 70n, discountTicketPrice: toNano("0.09"), referrerBonusPercent: 5n }));

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
