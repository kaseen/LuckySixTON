import { TonConnectButton } from '@tonconnect/ui-react';
import { useLuckySixContract } from './hooks/useLuckySixContract';
import { Box, TextField, Button } from '@mui/material';
import { styled } from '@mui/system';
import './App.css'

import { 
  bodyContainerStyle, 
  roundInfoStyle,
  contractAddress, 
  connectButton
} from './UI';
import { useState } from 'react';

const packCombinationToBePlayed = (arr: Array<bigint>) => {
  let result = 0n;
  for(let i = 0; i < 6; i++){
      result = result | arr[i];
      result <<= 6n;
  }
  result >>= 6n;

  return result;
}

function App() {
  const { roundInfo, lotteryState, address, sendCombination } = useLuckySixContract();
  const [combination, _setCombination] = useState([0n,0n,0n,0n,0n,0n]);
  const [render, setRender] = useState(0);
  const [amountToPlay, setAmountToPlay] = useState(0n);

  const setCombination = (i: number, v: number) => {
    const tmpCombination = combination;
    tmpCombination[i] = BigInt(v);
    _setCombination(tmpCombination);

    render === 0 ? setRender(1) : setRender(0);
  }

  const ButtonStyled = styled(Button)({
      backgroundColor: 'rgba(9,9,121,0.4)',
      borderRadius: '5px',
      border: '2px solid black',
      marginBottom: '10px',
  });

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

        <Box sx={{ padding: '5px'}}>
          <section>
              {
                  Array.from({ length: 3 },
                  (_, i) =>
                  <TextField
                      key={i}
                      onChange={(v) => setCombination(i, Number(v.target.value))}
                      inputProps={{ min: 0, style: { textAlign: 'center' } }}
                      sx={{
                          width: 60,
                          height: 56,
                          marginLeft: '5px',
                          marginRight: '5px',
                          border: '2px solid black',
                          borderRadius: '10px'
                      }}
                  />
                  )
              }
              <section>
              </section>
              {
                  Array.from({ length: 3 },
                  (_, i) =>
                  <TextField
                      key={i+3}
                      onChange={(v) => setCombination(i+3, Number(v.target.value))}
                      inputProps={{ min: 0, style: { textAlign: 'center' } }}
                      sx={{
                          width: 60,
                          height: 56,
                          marginLeft: '5px',
                          marginRight: '5px',
                          border: '2px solid black',
                          borderRadius: '10px'
                      }}
                  />
                  )
              }
          </section>
        </Box>

        <Box>
          <TextField
              inputProps={{ min: 0, style: { textAlign: 'center' }}}
              onChange={(v) => setAmountToPlay(BigInt(v.target.value))}
              sx={{
                  border: '2px solid black',
                  borderRadius: '10px',
                  marginBottom: '5px'
              }}
          />
        </Box>

        <Box>
          <ButtonStyled
            variant='contained'
            size='large'
            onClick={() => console.log(packCombinationToBePlayed(combination), amountToPlay)}
          >
              PlayLottery
          </ButtonStyled>
        </Box>

      </Box>
    </Box>
  )
}

export default App
