import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/lucky_six.tact',
    options: {
        debug: true,
    },
};
