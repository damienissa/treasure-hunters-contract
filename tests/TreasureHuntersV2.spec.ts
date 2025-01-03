import { fromNano, toNano } from '@ton/core';
import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import '@ton/test-utils';
import { Expedition } from '../wrappers/Expedition';
import { TreasureHuntersV2 } from '../wrappers/TreasureHuntersV2';

describe('TreasureHuntersV2', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let treasureHunters: SandboxContract<TreasureHuntersV2>;
    const players: SandboxContract<TreasuryContract>[] = [];
    const numberOfPlayers = 20n; // Total players for the expedition
    const ticketPrice = '10'; // Ticket price in TON
    const discountTicketPrice = '5'; // Discount ticket price in TON

    beforeEach(async () => {
        blockchain = await Blockchain.create();
        deployer = await blockchain.treasury('deployer');
        // console.log(`Deployer Balance before the game: ${await deployer.getBalance()}`);
        treasureHunters = blockchain.openContract(await TreasureHuntersV2.fromInit(numberOfPlayers, 10n, 70n));

        // Deploy the contract
        const deployResult = await treasureHunters.send(
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
            to: treasureHunters.address,
            deploy: true,
            success: true,
        });

        // Create 20 players
        for (let i = 0; i < 22; i++) {
            players.push(await blockchain.treasury(`player_${i}`));
        }
    });

    it('should buy all tickets and print balances', async () => {
        let expedition: SandboxContract<Expedition> = blockchain.openContract(await Expedition.fromInit(await treasureHunters.getCurrentExpeditionNumber(), numberOfPlayers));

        for (const player of players) {
            const buyResult = await treasureHunters.send(
                player.getSender(),
                {
                    value: toNano(ticketPrice),
                },
                {
                    $$type: 'BuyTicket',
                }
            );
            console.log(`Player ${player.address} bought a ticket`);
            expect(buyResult.transactions).toHaveTransaction({
                from: player.address,
                to: treasureHunters.address,
                success: true,
            });
        }

        const withdrawalResult = await treasureHunters.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Withdraw',
            }
        );

        expect(withdrawalResult.transactions).toHaveTransaction({
            from: treasureHunters.address,
            to: deployer.address,
            success: true,
        });

        const deployerBalance = await deployer.getBalance() - 1000000000000000n;
        console.log(`Deployer Balance after the game: ${fromNano(deployerBalance)} TON`);
        console.log(`Deployer Balance after the game: ${Number(deployerBalance) / 1000000000 * 5.5} USDT`);
    },);
});
