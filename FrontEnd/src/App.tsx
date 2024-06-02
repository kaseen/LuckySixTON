import { TonConnectButton } from '@tonconnect/ui-react';
import { useLuckySixContract } from './hooks/useLuckySixContract';
import { Box } from '@mui/material';
import './App.css'

import { 
  bodyContainerStyle, 
  roundInfoStyle,
  contractAddress, 
  connectButton
} from './UI';

function App() {
  const { roundInfo, lotteryState, address } = useLuckySixContract();

  return (
    <Box>
      <Box sx={bodyContainerStyle}>
        <Box sx={connectButton}>
          <TonConnectButton />
        </Box>
        
        <Box sx={contractAddress}>
          <b>Contract address: </b>
          {address?.slice(0, 30) + '...'}
        </Box>
        <Box sx={roundInfoStyle}>
          <Box>
            <b>Round Number: </b>
            {roundInfo?.roundNumber.toString()}
          </Box>
          <Box>
            <b>Lottery State: </b>
            {lotteryState == 0 ? 'Ready' : (lotteryState == 1 ? 'Started' : 'Closed')}
          </Box>
          <b>Round ends: </b>
        </Box>
      </Box>
    </Box>
  )
}

export default App
