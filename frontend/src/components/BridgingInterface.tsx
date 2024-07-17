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
  useColorModeValue
} from "@chakra-ui/react";
import { FaExchangeAlt } from 'react-icons/fa';
import { 
  rupayaBridge, 
  binanceBridge, 
  getContractWithSigner, 
  checkNetwork,
  parseEther
} from '../utils/ethers';

interface BridgeTransaction {
  date: string;
  from: string;
  to: string;
  amount: string;
  status: string;
}

const BridgingInterface: React.FC = () => {
  const [sourceChain, setSourceChain] = useState('');
  const [destinationChain, setDestinationChain] = useState('');
  const [amount, setAmount] = useState('');
  const [transactionStatus, setTransactionStatus] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [transactions, setTransactions] = useState<BridgeTransaction[]>([]);
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

  const handleSubmit = async () => {
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

  return (
    <Box as="section" width="full" p={8} bg={bgColor} borderRadius="lg" boxShadow="xl" borderWidth={1} borderColor={borderColor}>
      <VStack spacing={6} align="stretch">
        <Flex direction={["column", "row"]} gap={4}>
          <Select 
            placeholder="Select source chain" 
            value={sourceChain} 
            onChange={(e) => setSourceChain(e.target.value)}
            variant="filled"
            flex={1}
          >
            <option value="rupaya">Rupaya</option>
            <option value="bsc">Binance Smart Chain</option>
          </Select>
          <Select 
            placeholder="Select destination chain" 
            value={destinationChain} 
            onChange={(e) => setDestinationChain(e.target.value)}
            variant="filled"
            flex={1}
          >
            <option value="rupaya">Rupaya</option>
            <option value="bsc">Binance Smart Chain</option>
          </Select>
        </Flex>
        <Input 
          placeholder="Enter amount" 
          value={amount} 
          onChange={(e) => setAmount(e.target.value)} 
          variant="filled"
        />
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
        <Text fontSize="lg" fontWeight="bold">Status: {transactionStatus}</Text>
        <Box overflowX="auto">
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