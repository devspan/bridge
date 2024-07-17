// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/RupayaBridge.sol";
import "../src/BinanceBridge.sol";

contract DeployBridge is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory rupayaRpcUrl = vm.envString("RUPAYA_RPC_URL");
        string memory binanceRpcUrl = vm.envString("BINANCE_TESTNET_RPC_URL");
        
        console.log("RUPAYA_RPC_URL:", rupayaRpcUrl);
        console.log("BINANCE_TESTNET_RPC_URL:", binanceRpcUrl);

        // Deploy RupayaBridge
        vm.createSelectFork(rupayaRpcUrl);
        vm.startBroadcast(deployerPrivateKey);
        RupayaBridge rupayaBridge = new RupayaBridge();
        vm.stopBroadcast();
        console.log("RupayaBridge deployed at:", address(rupayaBridge));

        // Deploy BinanceBridge
        vm.createSelectFork(binanceRpcUrl);
        vm.startBroadcast(deployerPrivateKey);
        BinanceBridge binanceBridge = new BinanceBridge();
        vm.stopBroadcast();
        console.log("BinanceBridge deployed at:", address(binanceBridge));
    }
}