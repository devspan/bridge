// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/BinanceBridge.sol";

contract BinanceBridgeTest is Test {
    BinanceBridge public bridge;
    address public admin = address(1);
    address public user = address(2);

    function setUp() public {
        vm.prank(admin);
        bridge = new BinanceBridge();
    }

    function testMint() public {
        uint256 amount = 100 ether;
        
        vm.prank(admin);
        bridge.mint(user, amount);

        assertEq(bridge.balanceOf(user), amount);
    }

    function testBurn() public {
        uint256 amount = 100 ether;
        
        vm.prank(admin);
        bridge.mint(user, amount);

        vm.warp(block.timestamp + 1 hours);

        vm.prank(user);
        bridge.burn(amount);

        assertEq(bridge.balanceOf(user), 0);
    }

    function testPause() public {
        vm.prank(admin);
        bridge.pause();

        vm.startPrank(admin);
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("Pausable: paused"))));
        bridge.mint(user, 1 ether);
        vm.stopPrank();
    }

    function testUnpause() public {
        vm.startPrank(admin);
        bridge.pause();
        bridge.unpause();
        vm.stopPrank();

        vm.prank(admin);
        bridge.mint(user, 1 ether);
        
        assertEq(bridge.balanceOf(user), 1 ether);
    }
}
