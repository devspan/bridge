// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/RupayaBridge.sol";
import "../src/BinanceBridge.sol";

contract DeployBridge is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        RupayaBridge rupayaBridge = new RupayaBridge();
        BinanceBridge binanceBridge = new BinanceBridge();

        vm.stopBroadcast();

        console.log("RupayaBridge deployed at:", address(rupayaBridge));
        console.log("BinanceBridge deployed at:", address(binanceBridge));
    }
}