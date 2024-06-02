import { useEffect, useState } from 'react';
import { LuckySix } from '../../../SmartContracts/wrappers/LuckySix';
import { useTonClient } from './useTonClient';
import { useAsyncInitialize } from './useAsyncInitialize';
import { Address, OpenedContract, toNano } from '@ton/core';
import { useTonConnect } from './useTonConnect';
import { useTonAddress } from '@tonconnect/ui-react';

type RoundInfo = {
    roundNumber: bigint;
    timeStarted: bigint;
    isStarted: boolean;
}

const CONTRACT_ADDRESS = 'EQCv9oMOPknyWSbUeqpNMFZdYxmrl871kKroUJzmuGW0GXPN';

export function useLuckySixContract() {
    const client = useTonClient();
    const [roundInfo, setRoundInfo] = useState<null | RoundInfo>();
    const [lotteryState, setLotteryState] = useState<null | number>();
    const [lastPlayedTicket, setLastPlayedTicket] = useState<null | bigint>();

    const { sender } = useTonConnect();
    const userFriendlyAddress = useTonAddress();

    const sleep = (time: number) => new Promise((resolve) => setTimeout(resolve, time));
  
    const luckySixContract = useAsyncInitialize(async () => {
        if (!client) return;
        const contract = new LuckySix(
            Address.parse(CONTRACT_ADDRESS)
        );
        return client.open(contract) as OpenedContract<LuckySix>;
    }, [client]);

    useEffect(() => {
        async function getRoundInfo() {
            if (!luckySixContract) return;
            setRoundInfo(null);
            setLotteryState(null);
            //setLastPlayedTicket(null);
            const roundInfo = await luckySixContract.getRoundInfo();
            const lotteryState = await luckySixContract.getLotteryState();
            setRoundInfo(roundInfo);
            setLotteryState(Number(lotteryState));
            setLastPlayedTicket((await luckySixContract.getLastPlayedTicket(Address.parse(userFriendlyAddress))).packedCombination);

            await sleep(10000);
            getRoundInfo();
        }
        getRoundInfo();
    }, [luckySixContract]);
  
    return {
        roundInfo: roundInfo,
        lotteryState: lotteryState,
        address: luckySixContract?.address.toString(),
        sendCombination: (packedCombination: bigint, value: bigint) => {
            return luckySixContract?.send(
                sender,
                { value },
                { $$type: 'PlayTicket', packedCombination }
            )
        },
        lastPlayedTicket: lastPlayedTicket
    };
  }