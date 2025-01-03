import { NetworkProvider } from '@ton/blueprint';
import { toNano } from '@ton/core';
import { TreasureHunters } from '../wrappers/TreasureHunters';

export async function run(provider: NetworkProvider) {
    const treasureHunters = provider.open(await TreasureHunters.fromInit({ $$type: 'Config', numberOfPlayers: 20n, ticketPrice: toNano("10"), treasurePercent: 70n, discountTicketPrice: toNano("8"), referrerBonusPercent: 5n }));

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

    console.log('ID', await treasureHunters.getContractBalance());
}
