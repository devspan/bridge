"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const ethers_1 = require("ethers");
const dotenv_1 = __importDefault(require("dotenv"));
const url_1 = require("url");
const path_1 = require("path");
const __filename = (0, url_1.fileURLToPath)(import.meta.url);
const __dirname = (0, path_1.dirname)(__filename);
dotenv_1.default.config({ path: `${__dirname}/../.env` });
const RUPAYA_RPC_URL = process.env.RUPAYA_RPC_URL;
const BINANCE_RPC_URL = process.env.BINANCE_TESTNET_RPC_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const RUPAYA_BRIDGE_ADDRESS = process.env.RUPAYA_BRIDGE_ADDRESS;
const BINANCE_BRIDGE_ADDRESS = process.env.BINANCE_BRIDGE_ADDRESS;
const rupayaProvider = new ethers_1.ethers.JsonRpcProvider(RUPAYA_RPC_URL);
const binanceProvider = new ethers_1.ethers.JsonRpcProvider(BINANCE_RPC_URL);
const wallet = new ethers_1.ethers.Wallet(PRIVATE_KEY, rupayaProvider);
const rupayaBridgeAbi = [
    "event Deposit(address indexed from, uint256 amount, uint256 timestamp)",
    "function withdraw(address to, uint256 amount)"
];
const binanceBridgeAbi = [
    "event Burn(address indexed from, uint256 amount, uint256 timestamp)",
    "function mint(address to, uint256 amount)"
];
const rupayaBridge = new ethers_1.ethers.Contract(RUPAYA_BRIDGE_ADDRESS, rupayaBridgeAbi, wallet);
const binanceBridge = new ethers_1.ethers.Contract(BINANCE_BRIDGE_ADDRESS, binanceBridgeAbi, wallet.connect(binanceProvider));
rupayaBridge.on("Deposit", async (from, amount, timestamp) => {
    console.log(`Deposit detected on Rupaya: ${from} deposited ${amount} RUPX`);
    try {
        const tx = await binanceBridge.mint(from, amount);
        await tx.wait();
        console.log(`BRUPX minted on Binance: ${from} received ${amount} BRUPX`);
    }
    catch (error) {
        console.error("Error minting BRUPX on Binance:", error);
    }
});
binanceBridge.on("Burn", async (from, amount, timestamp) => {
    console.log(`Burn detected on Binance: ${from} burned ${amount} BRUPX`);
    try {
        const tx = await rupayaBridge.withdraw(from, amount);
        await tx.wait();
        console.log(`RUPX released on Rupaya: ${from} received ${amount} RUPX`);
    }
    catch (error) {
        console.error("Error releasing RUPX on Rupaya:", error);
    }
});
console.log("Bridge bot is running...");
