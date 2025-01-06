import { toNano } from '@ton/core';
import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import '@ton/test-utils';
import { TreasureHuntersV2 } from '../wrappers/TreasureHuntersV2';

describe('TreasureHuntersV2', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let referrer: SandboxContract<TreasuryContract>;
    let treasureHuntersV2: SandboxContract<TreasureHuntersV2>;
    const players: SandboxContract<TreasuryContract>[] = [];
    const numberOfPlayers = 100; // Total players for the expedition
    const playersPerExpedition = 20n; // Players per expedition
    const ticketPrice = toNano('10'); // Ticket price in TON
    const discountTicketPrice = toNano('9'); // Ticket price in TON
    const treasurePercent = 70n; // Treasure percent
    const referrerBonusPercent = 5n; // Referrer bonus percent
    var iterations = 0;


    beforeEach(async () => {
        blockchain = await Blockchain.create();

        treasureHuntersV2 = blockchain.openContract(await TreasureHuntersV2.fromInit({ $$type: 'Config', numberOfPlayers: playersPerExpedition, ticketPrice: ticketPrice, treasurePercent: treasurePercent, discountTicketPrice: discountTicketPrice, referrerBonusPercent: referrerBonusPercent, },),);

        deployer = await blockchain.treasury('deployer');

        const deployResult = await treasureHuntersV2.send(
            deployer.getSender(),
            {
                value: toNano('1'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            }
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: treasureHuntersV2.address,
            deploy: true,
            success: true,
        });

        await treasureHuntersV2.send(deployer.getSender(), { value: toNano('100') }, null);

        for (let i = 0; i < numberOfPlayers; i++) {
            players.push(await blockchain.treasury(`player_${i}_${iterations}`));
        }
    });

    it('should start game', async () => {

        var counter = 0;
        for (const player of players) {
            const result = await treasureHuntersV2.send(player.getSender(), { value: ticketPrice }, { $$type: 'BuyTicket', referrer: null });
            expect(result.transactions).toHaveTransaction({
                from: player.address,
                to: treasureHuntersV2.address,
                success: true,
            });
            counter++;
        }

        const history = await treasureHuntersV2.getExpeditionHistory();
        console.log(history.values().map((x) => x.winners.values()));
        let listOfWinners = history.values().map((x) => x.winners.values());
        let winners = listOfWinners.flat();
        for (const player of players) {
            for (const winner of winners) {

                if (player.address === winner.player) {
                    console.log("Winner:", winner);
                    console.log("Player:", player.address);

                    expect(await player.getBalance()).toBeGreaterThan(0n);
                    let claimResult = await treasureHuntersV2.send(player.getSender(), { value: 0n }, { $$type: 'Claim', });
                    console.log(claimResult);
                }
            }
        }
    });
});
