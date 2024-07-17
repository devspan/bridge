// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/RupayaBridge.sol";

contract RupayaBridgeTest is Test {
    RupayaBridge public bridge;
    address public admin = address(1);
    address public user = address(2);

    function setUp() public {
        vm.prank(admin);
        bridge = new RupayaBridge();
    }

    function testDeposit() public {
        uint256 amount = 100 ether;
        vm.deal(user, amount);
        
        vm.prank(user);
        bridge.deposit{value: amount}();

        assertEq(address(bridge).balance, amount);
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

        vm.expectRevert("Pausable: paused");
        vm.prank(user);
        bridge.deposit{value: 1 ether}();
    }

    function testUnpause() public {
        vm.startPrank(admin);
        bridge.pause();
        bridge.unpause();
        vm.stopPrank();

        vm.prank(user);
        bridge.deposit{value: 1 ether}();
        
        assertEq(address(bridge).balance, 1 ether);
    }
}