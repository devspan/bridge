// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/RupayaBridge.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract RupayaBridgeTest is Test {
    RupayaBridge public bridge;
    address public admin = address(1);
    address public user = address(2);
    address public nonAdmin = address(3);

    function setUp() public {
        vm.startPrank(admin);
        bridge = new RupayaBridge();
        vm.stopPrank();
    }

    function testDeposit() public {
        uint256 amount = 1 ether;
        vm.deal(user, amount);

        vm.prank(user);
        bridge.deposit{value: amount}();

        assertEq(address(bridge).balance, amount);
    }

    function testWithdraw() public {
        uint256 amount = 1 ether;
        vm.deal(address(bridge), amount);

        address payable recipient = payable(address(4));
        uint256 initialBalance = recipient.balance;

        vm.prank(admin);
        bridge.withdraw(recipient, amount);

        assertEq(recipient.balance, initialBalance + amount);
    }

    function testDepositExceedingMaxAmount() public {
        uint256 maxAmount = bridge.MAX_TRANSFER_AMOUNT();
        uint256 exceedingAmount = maxAmount + 1 ether;

        vm.deal(user, exceedingAmount);
        vm.prank(user);
        vm.expectRevert("Amount exceeds maximum transfer limit");
        bridge.deposit{value: exceedingAmount}();
    }

    function testWithdrawMoreThanBalance() public {
        uint256 initialBalance = 100 ether;
        vm.deal(address(bridge), initialBalance);

        uint256 withdrawAmount = 101 ether;

        vm.prank(admin);
        vm.expectRevert("Insufficient balance in the contract");
        bridge.withdraw(payable(user), withdrawAmount);
    }

    function testNonAdminPause() public {
        vm.prank(nonAdmin);
        vm.expectRevert();
        bridge.pause();
    }

    function testNonAdminUnpause() public {
        vm.prank(admin);
        bridge.pause();

        vm.prank(nonAdmin);
        vm.expectRevert();
        bridge.unpause();
    }

    function testNonOperatorWithdraw() public {
        uint256 amount = 1 ether;
        vm.deal(address(bridge), amount);

        vm.prank(nonAdmin);
        vm.expectRevert();
        bridge.withdraw(payable(user), amount);
    }

    function testPause() public {
        vm.prank(admin);
        bridge.pause();

        vm.deal(user, 1 ether);
        vm.prank(user);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        bridge.deposit{value: 1 ether}();
    }

    function testUnpause() public {
        vm.prank(admin);
        bridge.pause();

        vm.prank(admin);
        bridge.unpause();

        uint256 amount = 1 ether;
        vm.deal(user, amount);
        vm.prank(user);
        bridge.deposit{value: amount}();

        assertEq(address(bridge).balance, amount);
    }

    function testDepositWithinCooldown() public {
        uint256 amount = 1 ether;
        vm.deal(user, 2 * amount);

        vm.prank(user);
        bridge.deposit{value: amount}();

        vm.prank(user);
        vm.expectRevert("Transfer cooldown not met");
        bridge.deposit{value: amount}();
    }
}