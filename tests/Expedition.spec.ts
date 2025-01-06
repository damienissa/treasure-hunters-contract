import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { toNano } from '@ton/core';
import { Expedition } from '../wrappers/Expedition';
import '@ton/test-utils';

describe('Expedition', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let expedition: SandboxContract<Expedition>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        expedition = blockchain.openContract(await Expedition.fromInit());

        deployer = await blockchain.treasury('deployer');

        const deployResult = await expedition.send(
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
            to: expedition.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and expedition are ready to use
    });
});
