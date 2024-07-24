// RupayaBridge.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/RupayaBridge.sol";

contract RupayaBridgeTest is Test {
    RupayaBridge public bridge;
    address public admin = address(1);
    address public user = address(2);
    address public operator = address(3);
    uint256 public constant INITIAL_MAX_TRANSFER_AMOUNT = 1000 ether;
    uint256 public constant INITIAL_TRANSFER_COOLDOWN = 1 hours;

    event MaxTransferAmountUpdated(uint256 newAmount, uint256 timestamp);
    event TransferCooldownUpdated(uint256 newCooldown, uint256 timestamp);

    function setUp() public {
        vm.startPrank(admin);
        bridge = new RupayaBridge(INITIAL_MAX_TRANSFER_AMOUNT, INITIAL_TRANSFER_COOLDOWN);
        bridge.grantRole(bridge.OPERATOR_ROLE(), operator);
        bridge.grantRole(bridge.ADMIN_ROLE(), admin);
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

        vm.prank(operator);
        bridge.withdraw(recipient, amount);

        assertEq(recipient.balance, initialBalance + amount);
    }

    function testDepositExceedingMaxAmount() public {
        uint256 maxAmount = bridge.maxTransferAmount();
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

        vm.prank(operator);
        vm.expectRevert("Insufficient balance in the contract");
        bridge.withdraw(payable(user), withdrawAmount);
    }

    function testNonAdminPause() public {
        vm.prank(user);
        vm.expectRevert();
        bridge.pause();
    }

    function testNonAdminUnpause() public {
        vm.prank(admin);
        bridge.pause();

        vm.prank(user);
        vm.expectRevert();
        bridge.unpause();
    }

    function testNonOperatorWithdraw() public {
        uint256 amount = 1 ether;
        vm.deal(address(bridge), amount);

        vm.prank(user);
        vm.expectRevert();
        bridge.withdraw(payable(user), amount);
    }

    function testPause() public {
        vm.prank(admin);
        bridge.pause();

        vm.expectRevert();
        vm.prank(user);
        bridge.deposit{value: 1 ether}();
    }

    function testUnpause() public {
        vm.startPrank(admin);
        bridge.pause();
        bridge.unpause();
        vm.stopPrank();

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

    function testSetMaxTransferAmount() public {
        uint256 newMaxAmount = 2000 ether;

        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit MaxTransferAmountUpdated(newMaxAmount, block.timestamp);
        bridge.setMaxTransferAmount(newMaxAmount);

        assertEq(bridge.maxTransferAmount(), newMaxAmount);
    }

    function testSetTransferCooldown() public {
        uint256 newCooldown = 2 hours;

        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit TransferCooldownUpdated(newCooldown, block.timestamp);
        bridge.setTransferCooldown(newCooldown);

        assertEq(bridge.transferCooldown(), newCooldown);
    }

    function testNonAdminSetMaxTransferAmount() public {
        uint256 newMaxAmount = 2000 ether;

        vm.prank(user);
        vm.expectRevert();
        bridge.setMaxTransferAmount(newMaxAmount);
    }

    function testNonAdminSetTransferCooldown() public {
        uint256 newCooldown = 2 hours;

        vm.prank(user);
        vm.expectRevert();
        bridge.setTransferCooldown(newCooldown);
    }

    receive() external payable {}
}