import { fromNano, toNano } from '@ton/core';
import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import '@ton/test-utils';
import { TreasureHunters } from '../wrappers/TreasureHunters';

describe('TreasureHunters - Full Expedition', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let referrer: SandboxContract<TreasuryContract>;
    let treasureHunters: SandboxContract<TreasureHunters>;
    const players: SandboxContract<TreasuryContract>[] = [];
    const numberOfPlayers = 6; // Total players for the expedition
    const playersPerExpedition = 6n; // Players per expedition
    const ticketPrice = toNano('0.1'); // Ticket price in TON
    const discountTicketPrice = toNano('0.09'); // Ticket price in TON
    const treasurePercent = 70n; // Treasure percent
    const referrerBonusPercent = 5n; // Referrer bonus percent
    var iterations = 0;

    beforeEach(async () => {
        blockchain = await Blockchain.create();
        deployer = await blockchain.treasury('deployer');
        referrer = await blockchain.treasury('referrer');
        console.log(`Deployer Balance before the game: ${await deployer.getBalance()}`);
        treasureHunters = blockchain.openContract(await TreasureHunters.fromInit({ $$type: 'Config', numberOfPlayers: playersPerExpedition, ticketPrice: ticketPrice, treasurePercent: treasurePercent, discountTicketPrice: discountTicketPrice, referrerBonusPercent: referrerBonusPercent }));
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

        await treasureHunters.send(deployer.getSender(), { value: toNano('10') }, null);

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

    it('should buy all tickets with normal price', async () => {
        const deployerBalanceBefore = await deployer.getBalance() - 1000000000000000n;
        console.log(`Deployer Balance before the game: ${fromNano(deployerBalanceBefore)} TON`);
        console.log(`Deployer Balance before the game: ${Number(deployerBalanceBefore) / 1000000000 * 5.5} USDT`);

        for (const player of players) {
            const buyResult = await treasureHunters.send(
                player.getSender(),
                {
                    value: ticketPrice,
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
        expect((await treasureHunters.getExpeditionLog()).values().length).toEqual(1);
        console.log(`Game log: `, (await treasureHunters.getExpeditionLog()).values().map((v) => `Loosers: ${v.losers.values()}, Winner: ${v.winners.values()}`));
    });

    // it('should buy all tickets with discount', async () => {
    //     const deployerBalanceBefore = await deployer.getBalance() - 1000000000000000n;
    //     console.log(`Deployer Balance before the game: ${fromNano(deployerBalanceBefore)} TON`);
    //     console.log(`Deployer Balance before the game: ${Number(deployerBalanceBefore) / 1000000000 * 5.5} USDT`);

    //     for (const player of players) {
    //         const buyResult = await treasureHunters.send(
    //             player.getSender(),
    //             {
    //                 value: discountTicketPrice,
    //             },
    //             {
    //                 $$type: 'BuyFirstTicketAfterReferral',
    //                 referrer: referrer.address,
    //             }
    //         );

    //         expect(buyResult.transactions).toHaveTransaction({
    //             from: player.address,
    //             to: treasureHunters.address,
    //             success: true,
    //         });
    //     }

    //     const withdrawalResult = await treasureHunters.send(
    //         deployer.getSender(),
    //         {
    //             value: toNano('0.05'),
    //         },
    //         {
    //             $$type: 'Withdraw',
    //         }
    //     );

    //     expect(withdrawalResult.transactions).toHaveTransaction({
    //         from: treasureHunters.address,
    //         to: deployer.address,
    //         success: true,
    //     });

    //     const deployerBalance = await deployer.getBalance() - 1000000000000000n;
    //     console.log(`Deployer Balance after the game: ${fromNano(deployerBalance)} TON`);
    //     console.log(`Deployer Balance after the game: ${Number(deployerBalance) / 1000000000 * 5.5} USDT`);
    //     expect((await treasureHunters.getExpeditionLog()).values().length).toEqual(numberOfPlayers / 20);
    //     console.log(`Game log: `, (await treasureHunters.getExpeditionLog()).values().map((v) => `Loosers: ${v.losers.values()}, Winner: ${v.winners.values()}`));
    //     const referrerBalance = await referrer.getBalance();
    //     console.log(`Referrer Balance after the game: ${fromNano(referrerBalance)} TON`);
    //     expect(referrerBalance).toBeGreaterThan(1000000000000000n);
    // });
});
