import React, { useState } from 'react';
import { ChakraProvider, Box } from "@chakra-ui/react"
import theme from './theme';
import Layout from './components/Layout';
import BridgingInterface from './components/BridgingInterface';
import IntroductionSection from './components/IntroductionSection';
import LandingPage from './components/LandingPage';

function App() {
  const [isWalletConnected, setIsWalletConnected] = useState(false);
  const [connectedAddress, setConnectedAddress] = useState('');

  const handleWalletConnected = (address: string) => {
    setIsWalletConnected(true);
    setConnectedAddress(address);
  };

  return (
    <ChakraProvider theme={theme}>
      <Layout>
        {!isWalletConnected ? (
          <LandingPage onWalletConnected={handleWalletConnected} />
        ) : (
          <Box maxWidth="1200px" margin="0 auto" padding={8}>
            <IntroductionSection />
            <BridgingInterface connectedAddress={connectedAddress} />
          </Box>
        )}
      </Layout>
    </ChakraProvider>
  );
}

export default App;