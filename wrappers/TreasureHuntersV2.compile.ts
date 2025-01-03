import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/treasure_hunters_v2.tact',
    options: {
        debug: true,
    },
};
