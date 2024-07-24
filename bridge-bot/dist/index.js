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

const rupayaProvider = new ethers.JsonRpcProvider(RUPAYA_RPC_URL);
const binanceProvider = new ethers.JsonRpcProvider(BINANCE_RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, rupayaProvider);

const rupayaBridgeAbi = [
    "event Deposit(address indexed from, uint256 amount, uint256 timestamp)",
    "event Withdraw(address indexed to, uint256 amount, uint256 timestamp)",
    "function withdraw(address to, uint256 amount)"
];

const binanceBridgeAbi = [
    "event Burn(address indexed from, uint256 amount, uint256 timestamp)",
    "event Mint(address indexed to, uint256 amount, uint256 timestamp)",
    "function mint(address to, uint256 amount)"
];

const rupayaBridge = new ethers.Contract(RUPAYA_BRIDGE_ADDRESS, rupayaBridgeAbi, wallet);
const binanceBridge = new ethers.Contract(BINANCE_BRIDGE_ADDRESS, binanceBridgeAbi, wallet.connect(binanceProvider));

rupayaBridge.on("Deposit", async (from, amount, timestamp) => {
    console.log(`Deposit detected on Rupaya: ${from} deposited ${amount.toString()} RUPX at ${new Date(timestamp * 1000).toISOString()}`);
    try {
        const tx = await binanceBridge.mint(from, amount);
        await tx.wait();
        console.log(`BRUPX minted on Binance: ${from} received ${amount.toString()} BRUPX`);
    } catch (error) {
        console.error("Error minting BRUPX on Binance:", error);
    }
});

rupayaBridge.on("Withdraw", async (to, amount, timestamp) => {
    console.log(`Withdraw detected on Rupaya: ${to} withdrew ${amount.toString()} RUPX at ${new Date(timestamp * 1000).toISOString()}`);
});

binanceBridge.on("Burn", async (from, amount, timestamp) => {
    console.log(`Burn detected on Binance: ${from} burned ${amount.toString()} BRUPX at ${new Date(timestamp * 1000).toISOString()}`);
    try {
        const tx = await rupayaBridge.withdraw(from, amount);
        await tx.wait();
        console.log(`RUPX released on Rupaya: ${from} received ${amount.toString()} RUPX`);
    } catch (error) {
        console.error("Error releasing RUPX on Rupaya:", error);
    }
});

binanceBridge.on("Mint", async (to, amount, timestamp) => {
    console.log(`Mint detected on Binance: ${to} minted ${amount.toString()} BRUPX at ${new Date(timestamp * 1000).toISOString()}`);
});

console.log("Bridge bot is running...");
