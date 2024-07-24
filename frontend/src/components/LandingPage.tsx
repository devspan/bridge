import React, { useState } from 'react';
import { 
  Box, 
  VStack, 
  Button, 
  Text, 
  useToast,
  Icon,
  useColorModeValue,
  Heading,
} from "@chakra-ui/react";
import { FaWallet } from 'react-icons/fa';
import { ethers } from 'ethers';

interface LandingPageProps {
  onWalletConnected: (address: string) => void;
}

declare global {
  interface Window {
    ethereum?: ethers.Eip1193Provider;
  }
}

const LandingPage: React.FC<LandingPageProps> = ({ onWalletConnected }) => {
  const [isConnecting, setIsConnecting] = useState(false);
  const toast = useToast();

  const bgColor = useColorModeValue('white', 'gray.800');
  const borderColor = useColorModeValue('gray.200', 'gray.700');

  const connectWallet = async () => {
    if (window.ethereum) {
      try {
        setIsConnecting(true);
        await window.ethereum.request({ method: 'eth_requestAccounts' });
        const provider = new ethers.BrowserProvider(window.ethereum);
        const signer = await provider.getSigner();
        const address = await signer.getAddress();
        onWalletConnected(address);
        toast({
          title: "Wallet connected",
          description: `Connected to ${address}`,
          status: "success",
          duration: 3000,
          isClosable: true,
        });
      } catch (error) {
        console.error('Failed to connect wallet:', error);
        toast({
          title: "Failed to connect wallet",
          description: error instanceof Error ? error.message : "An error occurred while connecting the wallet.",
          status: "error",
          duration: 5000,
          isClosable: true,
        });
      } finally {
        setIsConnecting(false);
      }
    } else {
      toast({
        title: "Metamask not detected",
        description: "Please install Metamask to use this application.",
        status: "warning",
        duration: 5000,
        isClosable: true,
      });
    }
  };

  return (
    <Box as="section" width="full" height="100vh" display="flex" alignItems="center" justifyContent="center" bg={bgColor}>
      <VStack spacing={6} align="stretch" p={8} borderRadius="lg" boxShadow="xl" borderWidth={1} borderColor={borderColor} maxWidth="400px" width="full">
        <Heading as="h1" size="xl" textAlign="center" mb={4}>
          Welcome to Rupaya Bridge
        </Heading>
        <Text textAlign="center" mb={6}>
          Connect your wallet to start bridging RUPX tokens between Rupaya and Binance Smart Chain networks.
        </Text>
        <Button
          colorScheme="brand"
          onClick={connectWallet}
          isLoading={isConnecting}
          loadingText="Connecting..."
          leftIcon={<Icon as={FaWallet} />}
          size="lg"
        >
          Connect Wallet
        </Button>
      </VStack>
    </Box>
  );
};

export default LandingPage;