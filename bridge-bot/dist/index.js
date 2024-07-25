import { ethers } from 'ethers';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config({ path: `${__dirname}/../.env` });

const RUPAYA_RPC_URL = process.env.RUPAYA_RPC_URL;
const BINANCE_RPC_URL = process.env.BINANCE_TESTNET_RPC_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const RUPAYA_BRIDGE_ADDRESS = process.env.RUPAYA_BRIDGE_ADDRESS;
const BINANCE_BRIDGE_ADDRESS = process.env.BINANCE_BRIDGE_ADDRESS;

if (!RUPAYA_RPC_URL || !BINANCE_RPC_URL || !PRIVATE_KEY || !RUPAYA_BRIDGE_ADDRESS || !BINANCE_BRIDGE_ADDRESS) {
    console.error("Missing environment variables. Please check your .env file.");
    process.exit(1);
}

const rupayaProvider = new ethers.JsonRpcProvider(RUPAYA_RPC_URL);
const binanceProvider = new ethers.JsonRpcProvider(BINANCE_RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, rupayaProvider);

const rupayaBridgeAbi = [
    "event Deposit(address indexed from, uint256 amount, uint256 timestamp)",
    "event Withdraw(address indexed to, uint256 amount, uint256 timestamp)",
    "function withdraw(address payable to, uint256 amount)",
    "function setMaxTransferAmount(uint256 newAmount)",
    "function setTransferCooldown(uint256 newCooldown)",
    "function maxTransferAmount() view returns (uint256)",
    "function transferCooldown() view returns (uint256)"
];

const binanceBridgeAbi = [
    "event Burn(address indexed from, uint256 amount, uint256 timestamp)",
    "event Mint(address indexed to, uint256 amount, uint256 timestamp)",
    "function mint(address to, uint256 amount)",
    "function setMaxTransferAmount(uint256 newAmount)",
    "function setTransferCooldown(uint256 newCooldown)",
    "function maxTransferAmount() view returns (uint256)",
    "function transferCooldown() view returns (uint256)"
];

const rupayaBridge = new ethers.Contract(RUPAYA_BRIDGE_ADDRESS, rupayaBridgeAbi, wallet);
const binanceBridge = new ethers.Contract(BINANCE_BRIDGE_ADDRESS, binanceBridgeAbi, wallet.connect(binanceProvider));

async function setupEventListeners() {
    try {
        rupayaBridge.on("Deposit", async (from, amount, timestamp) => {
            console.log(`Deposit detected on Rupaya: ${from} deposited ${ethers.formatEther(amount)} RUPX at ${new Date(Number(timestamp) * 1000).toISOString()}`);
            try {
                const tx = await binanceBridge.mint(from, amount);
                await tx.wait();
                console.log(`BRUPX minted on Binance: ${from} received ${ethers.formatEther(amount)} BRUPX`);
            } catch (error) {
                console.error("Error minting BRUPX on Binance:", error);
            }
        });

        binanceBridge.on("Burn", async (from, amount, timestamp) => {
            console.log(`Burn detected on Binance: ${from} burned ${ethers.formatEther(amount)} BRUPX at ${new Date(Number(timestamp) * 1000).toISOString()}`);
            try {
                const tx = await rupayaBridge.withdraw(from, amount);
                await tx.wait();
                console.log(`RUPX released on Rupaya: ${from} received ${ethers.formatEther(amount)} RUPX`);
            } catch (error) {
                console.error("Error releasing RUPX on Rupaya:", error);
            }
        });

        console.log("Bridge bot is running...");
    } catch (error) {
        console.error("Error setting up event listeners:", error);
        console.log("Retrying in 5 seconds...");
        setTimeout(setupEventListeners, 5000);
    }
}

setupEventListeners();