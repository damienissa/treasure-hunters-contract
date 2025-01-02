import { toNano } from '@ton/core';
import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import '@ton/test-utils';
import { TreasureHunters } from '../wrappers/TreasureHunters';

describe('TreasureHunters - Full Expedition', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let treasureHunters: SandboxContract<TreasureHunters>;
    const players: SandboxContract<TreasuryContract>[] = [];
    const numberOfPlayers = 20; // Total players for the expedition
    const ticketPrice = '10'; // Ticket price in TON

    beforeEach(async () => {
        blockchain = await Blockchain.create();
        deployer = await blockchain.treasury('deployer');
        treasureHunters = blockchain.openContract(await TreasureHunters.fromInit(deployer.address));

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

        // expect(deployResult.transactions).toHaveTransaction({
        //     from: deployer.address,
        //     to: treasureHunters.address,
        //     deploy: true,
        //     success: true,
        // });

        // Create 20 players
        for (let i = 0; i < numberOfPlayers; i++) {
            players.push(await blockchain.treasury(`player_${i}`));
        }
    });

    it('should buy all tickets and print balances', async () => {

        let totalFees = BigInt(0);

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
            totalFees += buyResult.transactions[0].totalFees.coins;
            console.log(`Player ${player.address.toString()} bought a ticket, fees: ${buyResult.transactions}`);
        }

        const expectedBalance = toNano((numberOfPlayers * parseInt(ticketPrice)).toString());
        const adjustedExpectedBalance = expectedBalance - totalFees;

        expect(0).toEqual(adjustedExpectedBalance);

        // Print all player balances
        console.log('Balances after expedition:');
        for (const player of players) {
            const playerBalance = await player.getBalance();
            // console.log(`Player ${player.address.toString()}: ${fromNano(playerBalance)} TON`);
        }
    });
});
