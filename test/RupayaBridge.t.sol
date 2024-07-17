// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/RupayaBridge.sol";

contract RupayaBridgeTest is Test {
    RupayaBridge public bridge;
    address public admin = address(1);
    address public user = address(2);

    function setUp() public {
        vm.startPrank(admin);
        bridge = new RupayaBridge();
        vm.stopPrank();
    }

    function testDeposit() public {
        uint256 amount = 100 ether;
        vm.deal(user, 2 * amount);  // Provide enough balance for two deposits

        vm.prank(user);
        bridge.deposit{value: amount}();

        assertEq(address(bridge).balance, amount);

        // Try to deposit again immediately (should fail)
        vm.expectRevert("Transfer cooldown not met");
        vm.prank(user);
        bridge.deposit{value: amount}();

        // Move time forward to bypass cooldown
        vm.warp(block.timestamp + bridge.TRANSFER_COOLDOWN());

        vm.prank(user);
        bridge.deposit{value: amount}();

        assertEq(address(bridge).balance, 2 * amount);
    }

    function testWithdraw() public {
        uint256 amount = 100 ether;
        vm.deal(address(bridge), amount);

        address payable recipient = payable(address(3));
        uint256 initialBalance = recipient.balance;

        vm.prank(admin);
        bridge.withdraw(recipient, amount);

        assertEq(recipient.balance, initialBalance + amount);
    }

    function testPause() public {
        vm.prank(admin);
        bridge.pause();

        vm.startPrank(user);
        vm.expectRevert();  // We expect any revert here, not a specific message
        bridge.deposit{value: 1 ether}();
        vm.stopPrank();
    }

    function testUnpause() public {
        vm.startPrank(admin);
        bridge.pause();
        bridge.unpause();
        vm.stopPrank();

        vm.warp(block.timestamp + bridge.TRANSFER_COOLDOWN()); // Advance the block timestamp to bypass the cooldown

        vm.deal(user, 1 ether);
        vm.prank(user);
        bridge.deposit{value: 1 ether}();

        assertEq(address(bridge).balance, 1 ether);
    }
}