import { ethers } from 'ethers';

// Debug logging
console.log('Environment variables:', process.env);

// Export environment variables for use in other parts of the application
export const RUPAYA_RPC_URL = process.env.REACT_APP_RUPAYA_RPC_URL;
export const BINANCE_TESTNET_RPC_URL = process.env.REACT_APP_BINANCE_TESTNET_RPC_URL;
export const ETHERSCAN_API_KEY = process.env.REACT_APP_ETHERSCAN_API_KEY;
export const BLOCKSCOUT_API_URL = process.env.REACT_APP_BLOCKSCOUT_API_URL;
export const RUPAYA_BRIDGE_ADDRESS = process.env.REACT_APP_RUPAYA_BRIDGE_ADDRESS;
export const BINANCE_BRIDGE_ADDRESS = process.env.REACT_APP_BINANCE_BRIDGE_ADDRESS;

// Debug logging
console.log('Loaded environment variables:', {
  RUPAYA_RPC_URL,
  BINANCE_TESTNET_RPC_URL,
  RUPAYA_BRIDGE_ADDRESS,
  BINANCE_BRIDGE_ADDRESS
});

if (!RUPAYA_RPC_URL || !BINANCE_TESTNET_RPC_URL) {
  throw new Error('RPC URLs are not defined in the environment variables');
}

if (!RUPAYA_BRIDGE_ADDRESS || !BINANCE_BRIDGE_ADDRESS) {
  throw new Error('Bridge addresses are not defined in the environment variables');
}

// Providers
export const rupayaProvider = new ethers.JsonRpcProvider(RUPAYA_RPC_URL);
export const binanceProvider = new ethers.JsonRpcProvider(BINANCE_TESTNET_RPC_URL);

// ABIs
export const rupayaBridgeABI = [
  "function deposit() payable",
  "function withdraw(address to, uint256 amount)",
  "function maxTransferAmount() view returns (uint256)",
  "function transferCooldown() view returns (uint256)",
  "event Deposit(address indexed from, uint256 amount, uint256 timestamp)",
  "event Withdraw(address indexed to, uint256 amount, uint256 timestamp)"
] as const;

export const binanceBridgeABI = [
  "function mint(address to, uint256 amount)",
  "function burn(uint256 amount)",
  "function maxTransferAmount() view returns (uint256)",
  "function transferCooldown() view returns (uint256)",
  "event Burn(address indexed from, uint256 amount, uint256 timestamp)",
  "event Mint(address indexed to, uint256 amount, uint256 timestamp)"
] as const;

// Contract types
interface RupayaBridge extends ethers.BaseContract {
  deposit(overrides?: ethers.Overrides & { value?: ethers.BigNumberish }): Promise<ethers.ContractTransactionResponse>;
  withdraw(to: string, amount: ethers.BigNumberish): Promise<ethers.ContractTransactionResponse>;
  maxTransferAmount(): Promise<bigint>;
  transferCooldown(): Promise<bigint>;
}

interface BinanceBridge extends ethers.BaseContract {
  mint(to: string, amount: ethers.BigNumberish): Promise<ethers.ContractTransactionResponse>;
  burn(amount: ethers.BigNumberish): Promise<ethers.ContractTransactionResponse>;
  maxTransferAmount(): Promise<bigint>;
  transferCooldown(): Promise<bigint>;
}

// Contract instances
export const rupayaBridge = new ethers.Contract(RUPAYA_BRIDGE_ADDRESS, rupayaBridgeABI, rupayaProvider) as unknown as RupayaBridge;
export const binanceBridge = new ethers.Contract(BINANCE_BRIDGE_ADDRESS, binanceBridgeABI, binanceProvider) as unknown as BinanceBridge;

// Helper function to get signer
export const getSigner = async () => {
  if (typeof window !== 'undefined' && typeof (window as any).ethereum !== 'undefined') {
    await (window as any).ethereum.request({ method: 'eth_requestAccounts' });
    const provider = new ethers.BrowserProvider((window as any).ethereum);
    return provider.getSigner();
  } else {
    throw new Error("Ethereum wallet is not detected. Please install MetaMask or another Ethereum-compatible wallet.");
  }
};

// Helper function to get contract with signer
export const getContractWithSigner = async <T extends ethers.BaseContract>(contract: T): Promise<T> => {
  const signer = await getSigner();
  return contract.connect(signer) as T;
};

// Function to check if MetaMask is installed and connected to the correct network
export const checkNetwork = async (expectedChainId: number) => {
  if (typeof window !== 'undefined' && typeof (window as any).ethereum !== 'undefined') {
    const chainId = await (window as any).ethereum.request({ method: 'eth_chainId' });
    if (parseInt(chainId as string, 16) !== expectedChainId) {
      throw new Error(`Please switch to the correct network in your wallet. Expected chain ID: ${expectedChainId}`);
    }
  } else {
    throw new Error("Ethereum wallet is not detected. Please install MetaMask or another Ethereum-compatible wallet.");
  }
};

export const parseEther = ethers.parseEther;
export const formatEther = ethers.formatEther;

// Bridge bot functionality
export const setupBridgeListeners = (
  onDeposit: (from: string, amount: bigint, timestamp: bigint) => void,
  onBurn: (from: string, amount: bigint, timestamp: bigint) => void
) => {
  rupayaBridge.on("Deposit", (from, amount, timestamp) => {
    console.log(`Deposit detected on Rupaya: ${from} deposited ${formatEther(amount)} RUPX`);
    onDeposit(from, amount, timestamp);
  });

  binanceBridge.on("Burn", (from, amount, timestamp) => {
    console.log(`Burn detected on Binance: ${from} burned ${formatEther(amount)} BRUPX`);
    onBurn(from, amount, timestamp);
  });

  console.log("Bridge listeners are set up.");
};

export const mintOnBinance = async (to: string, amount: bigint) => {
  try {
    const tx = await binanceBridge.mint(to, amount);
    await tx.wait();
    console.log(`BRUPX minted on Binance: ${to} received ${formatEther(amount)} BRUPX`);
  } catch (error) {
    console.error("Error minting BRUPX on Binance:", error);
    throw error;
  }
};

export const withdrawOnRupaya = async (to: string, amount: bigint) => {
  try {
    const tx = await rupayaBridge.withdraw(to, amount);
    await tx.wait();
    console.log(`RUPX released on Rupaya: ${to} received ${formatEther(amount)} RUPX`);
  } catch (error) {
    console.error("Error releasing RUPX on Rupaya:", error);
    throw error;
  }
};

// Helper functions to get max transfer amount and transfer cooldown
export const getMaxTransferAmount = async (bridge: RupayaBridge | BinanceBridge): Promise<string> => {
  const amount = await bridge.maxTransferAmount();
  return formatEther(amount);
};

export const getTransferCooldown = async (bridge: RupayaBridge | BinanceBridge): Promise<number> => {
  return Number(await bridge.transferCooldown());
};