import { fromNano, toNano } from '@ton/core';
import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import '@ton/test-utils';
import { TreasureHunters } from '../wrappers/TreasureHunters';

describe('TreasureHunters - Full Expedition', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let treasureHunters: SandboxContract<TreasureHunters>;
    const players: SandboxContract<TreasuryContract>[] = [];
    const numberOfPlayers = 1000; // Total players for the expedition
    const ticketPrice = '10'; // Ticket price in TON
    const discountTicketPrice = '5'; // Discount ticket price in TON
    var iterations = 0;

    beforeEach(async () => {
        blockchain = await Blockchain.create();
        deployer = await blockchain.treasury('deployer');
        console.log(`Deployer Balance before the game: ${await deployer.getBalance()}`);
        treasureHunters = blockchain.openContract(await TreasureHunters.fromInit());
        iterations++;

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
        for (let i = 0; i < numberOfPlayers; i++) {
            players.push(await blockchain.treasury(`player_${i}_${iterations}`));
        }
    });

    it('should buy all tickets and print balances', async () => {
        const deployerBalanceBefore = await deployer.getBalance() - 1000000000000000n;
        console.log(`Deployer Balance before the game: ${fromNano(deployerBalanceBefore)} TON`);
        console.log(`Deployer Balance before the game: ${Number(deployerBalanceBefore) / 1000000000 * 5.5} USDT`);

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
    });
});
