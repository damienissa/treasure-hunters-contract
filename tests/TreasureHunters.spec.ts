import { fromNano, toNano } from '@ton/core';
import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import '@ton/test-utils';
import { TreasureHunters } from '../wrappers/TreasureHunters';

describe('TreasureHunters', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let referrer: SandboxContract<TreasuryContract>;
    let treasureHunters: SandboxContract<TreasureHunters>;
    var players: SandboxContract<TreasuryContract>[] = [];

    const numberOfPlayers = 100; // Total players for the expedition
    const playersPerExpedition = 10n; // Players per expedition
    const ticketPrice = toNano('10'); // Ticket price in TON
    const discountTicketPrice = toNano('9'); // Ticket price in TON
    const treasurePercent = 70n; // Treasure percent
    const referrerBonusPercent = 5n; // Referrer bonus percent
    var iterations = 0;


    beforeEach(async () => {
        blockchain = await Blockchain.create();

        treasureHunters = blockchain.openContract(await TreasureHunters.fromInit({ $$type: 'Config', numberOfPlayers: playersPerExpedition, ticketPrice: ticketPrice, treasurePercent: treasurePercent, referrerBonusPercent: referrerBonusPercent, },),);

        deployer = await blockchain.treasury('deployer');
        referrer = await blockchain.treasury('referrer');

        const deployResult = await treasureHunters.send(
            deployer.getSender(),
            {
                value: toNano('0.5'),
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
        players = [];
        for (let i = 0; i < numberOfPlayers; i++) {
            players.push(await blockchain.treasury(`player_${i}_${iterations}`));
        }
    });

    it('should play the game', async () => {
        for (const player of players) {
            const result = await treasureHunters.send(player.getSender(), { value: ticketPrice }, { $$type: 'BuyTicket', referrer: null });
            expect(result.transactions).toHaveTransaction({
                from: player.address,
                to: treasureHunters.address,
                success: true,
            });
        }

        const history = await treasureHunters.getExpeditionHistory();
        let listOfWinners = history.values().map((x) => x.winners.values());
        let winners = listOfWinners.flat();
        const wonPlayers = players.filter(player =>
            winners.some(winner => winner.player.toString() === player.address.toString())
        );
        for (const winner of wonPlayers) {
            const balanceBefore = await winner.getBalance();
            const canBeClaimed = await treasureHunters.getCanBeClaimed(winner.address);
            console.log("Winner:", winner.address.toString(), "Can be claimed:", fromNano(canBeClaimed || 0), "TON");
            const result = await treasureHunters.send(winner.getSender(), { value: toNano("0.5") }, { $$type: 'Claim', });
            expect(result.transactions).toHaveTransaction({
                from: treasureHunters.address,
                to: winner.address,
                success: true,
            });
            const balanceAfter = await winner.getBalance();
            expect(balanceAfter).toBeGreaterThan(balanceBefore);
        }

        const canBeWithdrawn = await treasureHunters.getAvailableForWithdraw();
        console.log("Can be withdrawn:", fromNano(canBeWithdrawn || 0), "TON");

        const deployerBefore = await deployer.getBalance();
        const result = await treasureHunters.send(deployer.getSender(), { value: toNano("0.5") }, { $$type: 'Withdraw', });
        expect(result.transactions).toHaveTransaction({
            from: treasureHunters.address,
            to: deployer.address,
            success: true,
        });

        const deployerAfter = await deployer.getBalance();

        console.log("Delta:", fromNano(deployerAfter - deployerBefore));
        console.log("Contract balance:", fromNano(await treasureHunters.getContractBalance()));
    });

    it('Referrer can see referral bonus balance', async () => {
        for (const player of players) {
            const result = await treasureHunters.send(player.getSender(), { value: ticketPrice }, { $$type: 'BuyTicket', referrer: referrer.address });
            expect(result.transactions).toHaveTransaction({
                from: player.address,
                to: treasureHunters.address,
                success: true,
            });
        }
        const referrerBonus = await treasureHunters.getReferralBonusBalance(referrer.address);
        console.log("Referrer bonus:", fromNano(referrerBonus || 0), "TON");
        expect(referrerBonus).toBeGreaterThan(0);
    });

    it('Referrer can withdraw referral bonus balance', async () => {
        for (const player of players) {
            const result = await treasureHunters.send(player.getSender(), { value: ticketPrice }, { $$type: 'BuyTicket', referrer: referrer.address });
            expect(result.transactions).toHaveTransaction({
                from: player.address,
                to: treasureHunters.address,
                success: true,
            });
        }
        const referrerBalanceBefore = await referrer.getBalance();
        console.log("Referrer balance before:", fromNano(referrerBalanceBefore), "TON");
        const referrerBonusResult = await treasureHunters.send(referrer.getSender(), { value: toNano("0.5") }, { $$type: 'RequestReferralBonus', });
        expect(referrerBonusResult.transactions).toHaveTransaction({
            from: referrer.address,
            to: treasureHunters.address,
            success: true,
        });
        const referrerBalanceAfter = await referrer.getBalance();
        console.log("Referrer balance after:", fromNano(referrerBalanceAfter), "TON");
        expect(referrerBalanceAfter).toBeGreaterThan(referrerBalanceBefore);
    });
});
