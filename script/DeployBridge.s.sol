// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/RupayaBridge.sol";
import "../src/BinanceBridge.sol";

contract DeployBridge is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        uint256 initialMaxTransferAmount = 1000 ether; // Set your desired initial max transfer amount
        uint256 initialTransferCooldown = 1 hours; // Set your desired initial transfer cooldown

        RupayaBridge rupayaBridge = new RupayaBridge(initialMaxTransferAmount, initialTransferCooldown);
        console.log("RupayaBridge deployed at:", address(rupayaBridge));

        BinanceBridge binanceBridge = new BinanceBridge(initialMaxTransferAmount, initialTransferCooldown);
        console.log("BinanceBridge deployed at:", address(binanceBridge));

        vm.stopBroadcast();
    }
}