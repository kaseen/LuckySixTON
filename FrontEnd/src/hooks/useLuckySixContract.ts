import { useEffect, useState } from 'react';
import { LuckySix } from '../../../SmartContracts/wrappers/LuckySix';
import { useTonClient } from './useTonClient';
import { useAsyncInitialize } from './useAsyncInitialize';
import { Address, OpenedContract } from '@ton/core';

type RoundInfo = {
    roundNumber: bigint;
    timeStarted: bigint;
    isStarted: boolean;
}

export function useLuckySixContract() {
    const client = useTonClient();
    const [roundInfo, setRoundInfo] = useState<null | RoundInfo>();
    const [lotteryState, setLotteryState] = useState<null | number>();
  
    const luckySixContract = useAsyncInitialize(async () => {
        if (!client) return;
        const contract = new LuckySix(
            Address.parse('EQCv9oMOPknyWSbUeqpNMFZdYxmrl871kKroUJzmuGW0GXPN') // replace with your address from tutorial 2 step 8
        );
        return client.open(contract) as OpenedContract<LuckySix>;
    }, [client]);
  
    useEffect(() => {
        async function getRoundInfo() {
            if (!luckySixContract) return;
            setRoundInfo(null);
            setLotteryState(null);
            const roundInfo = await luckySixContract.getRoundInfo();
            const lotteryState = await luckySixContract.getLotteryState();
            setRoundInfo(roundInfo);
            setLotteryState(Number(lotteryState));
        }
        getRoundInfo();
    }, [luckySixContract]);
  
    return {
        roundInfo: roundInfo,
        lotteryState: lotteryState,
        address: luckySixContract?.address.toString(),
    };
  }