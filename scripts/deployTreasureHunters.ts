import { NetworkProvider } from '@ton/blueprint';
import { toNano } from '@ton/core';
import { TreasureHunters } from '../wrappers/TreasureHunters';

export async function run(provider: NetworkProvider) {
    const treasureHunters = provider.open(await TreasureHunters.fromInit({ $$type: 'Config', numberOfPlayers: 6n, ticketPrice: toNano("0.1"), treasurePercent: 70n, discountTicketPrice: toNano("0.09"), referrerBonusPercent: 5n }));

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
    /// Add initial balance
    await treasureHunters.send(provider.sender(), { value: toNano('1') }, null);

    console.log('ID', await treasureHunters.getContractBalance());
}
