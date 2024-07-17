import { ethers } from 'ethers';

// RPC URLs
const RUPAYA_RPC_URL = 'https://rpc.testnet.rupaya.io';
const BINANCE_RPC_URL = 'https://data-seed-prebsc-2-s1.binance.org:8545/';

// Providers
export const rupayaProvider = new ethers.providers.JsonRpcProvider(RUPAYA_RPC_URL);
export const binanceProvider = new ethers.providers.JsonRpcProvider(BINANCE_RPC_URL);

// Contract addresses
export const rupayaBridgeAddress = '0xD52c93b4bc11176137032bDaD065896F72D74da5';
export const binanceBridgeAddress = '0x4e8d6B7422d0a25Ac07D8Ce33789e7E5bd625A82';

// ABIs
export const rupayaBridgeABI = [
  "function deposit() payable",
  "function withdraw(address to, uint256 amount)",
  "event Deposit(address indexed from, uint256 amount, uint256 timestamp)"
];

export const binanceBridgeABI = [
  "function mint(address to, uint256 amount)",
  "function burn(uint256 amount)",
  "event Burn(address indexed from, uint256 amount, uint256 timestamp)"
];

// Contract instances
export const rupayaBridge = new ethers.Contract(rupayaBridgeAddress, rupayaBridgeABI, rupayaProvider);
export const binanceBridge = new ethers.Contract(binanceBridgeAddress, binanceBridgeABI, binanceProvider);

// Helper function to get signer
export const getSigner = async () => {
  if (typeof window !== 'undefined' && typeof (window as any).ethereum !== 'undefined') {
    await (window as any).ethereum.request({ method: 'eth_requestAccounts' });
    const provider = new ethers.providers.Web3Provider((window as any).ethereum);
    return provider.getSigner();
  } else {
    throw new Error("Ethereum wallet is not detected. Please install MetaMask or another Ethereum-compatible wallet.");
  }
};

// Helper function to get contract with signer
export const getContractWithSigner = async (contract: ethers.Contract) => {
  const signer = await getSigner();
  return contract.connect(signer);
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

export const parseEther = ethers.utils.parseEther;