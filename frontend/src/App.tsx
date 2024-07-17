import React from 'react';
import { ChakraProvider, Box } from "@chakra-ui/react"
import theme from './theme';
import Layout from './components/Layout';
import BridgingInterface from './components/BridgingInterface';
import IntroductionSection from './components/IntroductionSection';

function App() {
  return (
    <ChakraProvider theme={theme}>
      <Layout>
        <Box maxWidth="1200px" margin="0 auto" padding={8}>
          <IntroductionSection />
          <BridgingInterface />
        </Box>
      </Layout>
    </ChakraProvider>
  );
}

export default App;