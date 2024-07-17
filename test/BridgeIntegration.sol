// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/RupayaBridge.sol";
import "../src/BinanceBridge.sol";

contract BridgeIntegrationTest is Test {
    RupayaBridge public rupayaBridge;
    BinanceBridge public binanceBridge;
    address public admin = address(1);
    address public user = address(2);
    address public operator = address(3);

    function setUp() public {
        vm.startPrank(admin);
        rupayaBridge = new RupayaBridge();
        binanceBridge = new BinanceBridge();
        rupayaBridge.grantRole(rupayaBridge.OPERATOR_ROLE(), operator);
        binanceBridge.grantRole(binanceBridge.OPERATOR_ROLE(), operator);
        vm.stopPrank();
    }

    function testFullBridgeProcess() public {
        uint256 amount = 1 ether;
        
        // Step 1: User deposits RUPX to RupayaBridge
        vm.deal(user, amount);
        vm.prank(user);
        rupayaBridge.deposit{value: amount}();
        assertEq(address(rupayaBridge).balance, amount);

        // Step 2: Operator mints BRUPX on BinanceBridge
        vm.prank(operator);
        binanceBridge.mint(user, amount);
        assertEq(binanceBridge.balanceOf(user), amount);

        // Step 3: User burns BRUPX on BinanceBridge
        vm.warp(block.timestamp + binanceBridge.TRANSFER_COOLDOWN());
        vm.prank(user);
        binanceBridge.burn(amount);
        assertEq(binanceBridge.balanceOf(user), 0);

        // Step 4: Operator withdraws RUPX from RupayaBridge
        uint256 initialUserBalance = user.balance;
        vm.prank(operator);
        rupayaBridge.withdraw(payable(user), amount);
        assertEq(user.balance, initialUserBalance + amount);
        assertEq(address(rupayaBridge).balance, 0);
    }

    function testBridgeWithInsufficientFunds() public {
        uint256 depositAmount = 1 ether;
        uint256 withdrawAmount = 2 ether;

        // User deposits RUPX to RupayaBridge
        vm.deal(user, depositAmount);
        vm.prank(user);
        rupayaBridge.deposit{value: depositAmount}();

        // Operator tries to withdraw more than deposited
        vm.prank(operator);
        vm.expectRevert("Insufficient balance in the contract");
        rupayaBridge.withdraw(payable(user), withdrawAmount);
    }

    function testBridgeWithUnauthorizedOperator() public {
        uint256 amount = 1 ether;

        // Unauthorized user tries to mint BRUPX
        vm.prank(user);
        vm.expectRevert();
        binanceBridge.mint(user, amount);

        // Unauthorized user tries to withdraw RUPX
        vm.prank(user);
        vm.expectRevert();
        rupayaBridge.withdraw(payable(user), amount);
    }

    function testBridgeWithExceedingMaxAmount() public {
        uint256 maxAmount = rupayaBridge.MAX_TRANSFER_AMOUNT();
        uint256 exceedingAmount = maxAmount + 1 ether;

        // Try to deposit more than MAX_TRANSFER_AMOUNT
        vm.deal(user, exceedingAmount);
        vm.prank(user);
        vm.expectRevert("Amount exceeds maximum transfer limit");
        rupayaBridge.deposit{value: exceedingAmount}();

        // Try to mint more than MAX_TRANSFER_AMOUNT
        vm.prank(operator);
        vm.expectRevert("Amount exceeds maximum transfer limit");
        binanceBridge.mint(user, exceedingAmount);
    }

    function testBridgeWithCooldownPeriod() public {
        uint256 amount = 1 ether;

        // Mint BRUPX
        vm.prank(operator);
        binanceBridge.mint(user, amount);

        // Try to burn immediately (should fail due to cooldown)
        vm.prank(user);
        vm.expectRevert("Transfer cooldown not met");
        binanceBridge.burn(amount);

        // Wait for cooldown period
        vm.warp(block.timestamp + binanceBridge.TRANSFER_COOLDOWN());

        // Burn should succeed now
        vm.prank(user);
        binanceBridge.burn(amount);
        assertEq(binanceBridge.balanceOf(user), 0);
    }
}