import React, { useState, useEffect } from 'react';
import { 
  Box, 
  VStack, 
  Select, 
  Input, 
  Button, 
  Text, 
  Table, 
  Thead, 
  Tbody, 
  Tr, 
  Th, 
  Td, 
  useToast,
  Icon,
  Flex,
  useColorModeValue,
  Heading,
  Alert,
  AlertIcon,
  FormControl,
  FormLabel,
  FormErrorMessage,
  Spacer,
} from "@chakra-ui/react";
import { FaExchangeAlt, FaTrash } from 'react-icons/fa';
import { 
  rupayaBridge, 
  binanceBridge, 
  getContractWithSigner, 
  checkNetwork,
  parseEther,
  formatEther,
  RUPAYA_RPC_URL,
  BINANCE_TESTNET_RPC_URL
} from '../utils/ethers';

interface BridgeTransaction {
  date: string;
  from: string;
  to: string;
  amount: string;
  status: string;
}

interface BridgingInterfaceProps {
  connectedAddress: string;
}

const BridgingInterface: React.FC<BridgingInterfaceProps> = ({ connectedAddress }) => {
  const [sourceChain, setSourceChain] = useState('');
  const [destinationChain, setDestinationChain] = useState('');
  const [amount, setAmount] = useState('');
  const [transactionStatus, setTransactionStatus] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [transactions, setTransactions] = useState<BridgeTransaction[]>([]);
  const [formErrors, setFormErrors] = useState({ sourceChain: '', destinationChain: '', amount: '' });
  const [maxTransferAmount, setMaxTransferAmount] = useState('');
  const [transferCooldown, setTransferCooldown] = useState('');
  const toast = useToast();

  const bgColor = useColorModeValue('white', 'gray.800');
  const borderColor = useColorModeValue('gray.200', 'gray.700');
  const tableBgColor = useColorModeValue('gray.50', 'gray.700');

  useEffect(() => {
    const storedTransactions = localStorage.getItem('bridgeTransactions');
    if (storedTransactions) {
      setTransactions(JSON.parse(storedTransactions));
    }
  }, []);

  useEffect(() => {
    if (sourceChain) {
      updateBridgeInfo();
    }
  }, [sourceChain]);

  const updateBridgeInfo = async () => {
    try {
      const contract = sourceChain === 'rupaya' ? 
        await getContractWithSigner(rupayaBridge) : 
        await getContractWithSigner(binanceBridge);

      console.log("Current chain:", sourceChain);
      console.log("Contract address:", await contract.getAddress());
      console.log("RPC URL:", sourceChain === 'rupaya' ? RUPAYA_RPC_URL : BINANCE_TESTNET_RPC_URL);

      let maxAmount, cooldown;

      try {
        maxAmount = await contract.maxTransferAmount();
        console.log("Raw maxAmount:", maxAmount);
        setMaxTransferAmount(formatEther(maxAmount));
      } catch (error) {
        console.error("Error fetching maxTransferAmount:", error);
        setMaxTransferAmount("Error fetching");
      }

      try {
        cooldown = await contract.transferCooldown();
        console.log("Raw cooldown:", cooldown);
        setTransferCooldown(cooldown.toString());
      } catch (error) {
        console.error("Error fetching transferCooldown:", error);
        setTransferCooldown("Error fetching");
      }
    } catch (error) {
      console.error("Error fetching bridge info:", error);
      setMaxTransferAmount("Error");
      setTransferCooldown("Error");
    }
  };

  const validateForm = () => {
    const errors = { sourceChain: '', destinationChain: '', amount: '' };
    let isValid = true;

    if (!sourceChain) {
      errors.sourceChain = 'Source chain is required';
      isValid = false;
    }
    if (!destinationChain) {
      errors.destinationChain = 'Destination chain is required';
      isValid = false;
    }
    if (sourceChain === destinationChain) {
      errors.destinationChain = 'Source and destination chains must be different';
      isValid = false;
    }
    if (!amount || isNaN(Number(amount)) || Number(amount) <= 0) {
      errors.amount = 'Please enter a valid amount';
      isValid = false;
    }
    if (Number(amount) > Number(maxTransferAmount)) {
      errors.amount = `Amount exceeds maximum transfer limit of ${maxTransferAmount} RUPX`;
      isValid = false;
    }

    setFormErrors(errors);
    return isValid;
  };

  const handleSubmit = async () => {
    if (!validateForm()) return;

    try {
      setIsLoading(true);
      setTransactionStatus('Processing...');
      if (sourceChain === 'rupaya' && destinationChain === 'bsc') {
        await checkNetwork(799); // Rupaya testnet chain ID
        const rupayaBridgeWithSigner = await getContractWithSigner(rupayaBridge);
        const tx = await rupayaBridgeWithSigner.deposit({ value: parseEther(amount) });
        await tx.wait();
        addTransaction('Rupaya', 'BSC', amount, 'Completed');
        toast({
          title: "Deposit successful",
          description: "Tokens have been deposited to the Rupaya bridge.",
          status: "success",
          duration: 5000,
          isClosable: true,
        });
      } else if (sourceChain === 'bsc' && destinationChain === 'rupaya') {
        await checkNetwork(97); // BSC testnet chain ID
        const binanceBridgeWithSigner = await getContractWithSigner(binanceBridge);
        const tx = await binanceBridgeWithSigner.burn(parseEther(amount));
        await tx.wait();
        addTransaction('BSC', 'Rupaya', amount, 'Completed');
        toast({
          title: "Burn successful",
          description: "Tokens have been burned on the Binance bridge.",
          status: "success",
          duration: 5000,
          isClosable: true,
        });
      }
      setTransactionStatus('Completed');
    } catch (error) {
      console.error(error);
      setTransactionStatus('Failed');
      toast({
        title: "Transaction failed",
        description: error instanceof Error ? error.message : "An error occurred while processing the transaction.",
        status: "error",
        duration: 5000,
        isClosable: true,
      });
    } finally {
      setIsLoading(false);
    }
  };

  const addTransaction = (from: string, to: string, amount: string, status: string) => {
    const newTransaction: BridgeTransaction = {
      date: new Date().toISOString(),
      from,
      to,
      amount,
      status
    };
    const updatedTransactions = [...transactions, newTransaction];
    setTransactions(updatedTransactions);
    localStorage.setItem('bridgeTransactions', JSON.stringify(updatedTransactions));
  };

  const clearHistory = () => {
    setTransactions([]);
    localStorage.removeItem('bridgeTransactions');
    toast({
      title: "Transaction history cleared",
      status: "info",
      duration: 3000,
      isClosable: true,
    });
  };

  return (
    <Box as="section" width="full" p={8} bg={bgColor} borderRadius="lg" boxShadow="xl" borderWidth={1} borderColor={borderColor}>
      <VStack spacing={6} align="stretch">
        <Heading as="h1" size="xl" textAlign="center" mb={4}>
          Rupaya Bridge
        </Heading>
        <Text textAlign="center" mb={6}>
          Seamlessly transfer your RUPX tokens between Rupaya and Binance Smart Chain networks.
        </Text>
        <Text>Connected Wallet: {connectedAddress}</Text>
        <Text>Max Transfer Amount: {maxTransferAmount} RUPX</Text>
        <Text>Transfer Cooldown: {transferCooldown} seconds</Text>
        <Flex direction={["column", "row"]} gap={4}>
          <FormControl isInvalid={!!formErrors.sourceChain}>
            <FormLabel>Source Chain</FormLabel>
            <Select 
              placeholder="Select source chain" 
              value={sourceChain} 
              onChange={(e) => setSourceChain(e.target.value)}
              variant="filled"
            >
              <option value="rupaya">Rupaya</option>
              <option value="bsc">Binance Smart Chain</option>
            </Select>
            <FormErrorMessage>{formErrors.sourceChain}</FormErrorMessage>
          </FormControl>
          <FormControl isInvalid={!!formErrors.destinationChain}>
            <FormLabel>Destination Chain</FormLabel>
            <Select 
              placeholder="Select destination chain" 
              value={destinationChain} 
              onChange={(e) => setDestinationChain(e.target.value)}
              variant="filled"
            >
              <option value="rupaya">Rupaya</option>
              <option value="bsc">Binance Smart Chain</option>
            </Select>
            <FormErrorMessage>{formErrors.destinationChain}</FormErrorMessage>
          </FormControl>
        </Flex>
        <FormControl isInvalid={!!formErrors.amount}>
          <FormLabel>Amount</FormLabel>
          <Input 
            placeholder="Enter amount" 
            value={amount} 
            onChange={(e) => setAmount(e.target.value)} 
            variant="filled"
          />
          <FormErrorMessage>{formErrors.amount}</FormErrorMessage>
        </FormControl>
        <Button 
          colorScheme="brand" 
          onClick={handleSubmit} 
          isLoading={isLoading}
          loadingText="Processing"
          leftIcon={<Icon as={FaExchangeAlt} />}
          size="lg"
        >
          Bridge Tokens
        </Button>
        {transactionStatus && (
          <Alert status={transactionStatus === 'Completed' ? 'success' : transactionStatus === 'Failed' ? 'error' : 'info'}>
            <AlertIcon />
            Status: {transactionStatus}
          </Alert>
        )}
        <Box overflowX="auto">
          <Flex justify="space-between" align="center" mb={4}>
            <Heading as="h2" size="md">Transaction History</Heading>
            <Button leftIcon={<Icon as={FaTrash} />} onClick={clearHistory} size="sm" variant="outline">
              Clear History
            </Button>
          </Flex>
          <Table variant="simple">
            <Thead>
              <Tr>
                <Th>Date</Th>
                <Th>From</Th>
                <Th>To</Th>
                <Th>Amount</Th>
                <Th>Status</Th>
              </Tr>
            </Thead>
            <Tbody>
              {transactions.map((tx, index) => (
                <Tr key={index} bg={index % 2 === 0 ? tableBgColor : 'transparent'}>
                  <Td>{new Date(tx.date).toLocaleString()}</Td>
                  <Td>{tx.from}</Td>
                  <Td>{tx.to}</Td>
                  <Td>{tx.amount} RUPX</Td>
                  <Td>{tx.status}</Td>
                </Tr>
              ))}
            </Tbody>
          </Table>
        </Box>
      </VStack>
    </Box>
  );
};

export default BridgingInterface;