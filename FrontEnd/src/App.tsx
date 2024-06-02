import { TonConnectButton } from '@tonconnect/ui-react';
import { bodyContainerStyle, roundInfoStyle } from './UI';
import { useLuckySixContract } from './hooks/useLuckySixContract';
import { Box } from '@mui/material';
import './App.css'

function App() {
  const { roundInfo, lotteryState, address } = useLuckySixContract();

  return (
    <Box>
      <Box sx={bodyContainerStyle}>
        <TonConnectButton />

        <Box>
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
