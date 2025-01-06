import { toNano } from '@ton/core';
import { Expedition } from '../wrappers/Expedition';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const expedition = provider.open(await Expedition.fromInit());

    await expedition.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(expedition.address);

    // run methods on `expedition`
}
