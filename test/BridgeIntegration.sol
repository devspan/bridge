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
    address public minter = address(3);
    uint256 public constant INITIAL_MAX_TRANSFER_AMOUNT = 1000 ether;
    uint256 public constant INITIAL_TRANSFER_COOLDOWN = 1 hours;

    function setUp() public {
        vm.startPrank(admin);
        rupayaBridge = new RupayaBridge(INITIAL_MAX_TRANSFER_AMOUNT, INITIAL_TRANSFER_COOLDOWN);
        binanceBridge = new BinanceBridge(INITIAL_MAX_TRANSFER_AMOUNT, INITIAL_TRANSFER_COOLDOWN);
        rupayaBridge.grantRole(rupayaBridge.OPERATOR_ROLE(), minter);
        binanceBridge.grantRole(binanceBridge.MINTER_ROLE(), minter);
        vm.stopPrank();
    }

    function testFullBridgeProcess() public {
        uint256 amount = 1 ether;
        
        // Step 1: User deposits RUPX to RupayaBridge
        vm.deal(user, amount);
        vm.prank(user);
        rupayaBridge.deposit{value: amount}();
        assertEq(address(rupayaBridge).balance, amount);

        // Step 2: Minter mints BRUPX on BinanceBridge
        vm.prank(minter);
        binanceBridge.mint(user, amount);
        assertEq(binanceBridge.balanceOf(user), amount);

        // Step 3: User burns BRUPX on BinanceBridge
        vm.warp(block.timestamp + binanceBridge.transferCooldown());
        vm.prank(user);
        binanceBridge.burn(amount);
        assertEq(binanceBridge.balanceOf(user), 0);

        // Step 4: Operator withdraws RUPX from RupayaBridge
        uint256 initialUserBalance = user.balance;
        vm.prank(minter);
        rupayaBridge.withdraw(payable(user), amount);
        assertEq(user.balance, initialUserBalance + amount);
        assertEq(address(rupayaBridge).balance, 0);
    }

    function testDepositExceedingMaxAmount() public {
        uint256 exceedingAmount = INITIAL_MAX_TRANSFER_AMOUNT + 1 ether;
        vm.deal(user, exceedingAmount);
        
        vm.prank(user);
        vm.expectRevert("Amount exceeds maximum transfer limit");
        rupayaBridge.deposit{value: exceedingAmount}();
    }

    function testMintExceedingMaxAmount() public {
        uint256 exceedingAmount = INITIAL_MAX_TRANSFER_AMOUNT + 1 ether;
        
        vm.prank(minter);
        vm.expectRevert("Amount exceeds maximum transfer limit");
        binanceBridge.mint(user, exceedingAmount);
    }

    function testDepositWithinCooldown() public {
        uint256 amount = 1 ether;
        vm.deal(user, amount * 2);

        vm.prank(user);
        rupayaBridge.deposit{value: amount}();

        vm.prank(user);
        vm.expectRevert("Transfer cooldown not met");
        rupayaBridge.deposit{value: amount}();
    }

    function testBurnWithinCooldown() public {
        uint256 amount = 1 ether;

        vm.prank(minter);
        binanceBridge.mint(user, amount);

        vm.prank(user);
        vm.expectRevert("Transfer cooldown not met");
        binanceBridge.burn(amount);
    }

    function testUnauthorizedWithdraw() public {
        uint256 amount = 1 ether;
        vm.deal(address(rupayaBridge), amount);

        vm.prank(user);
        vm.expectRevert();
        rupayaBridge.withdraw(payable(user), amount);
    }

function testPausedDeposit() public {
    uint256 amount = 1 ether;
    vm.deal(user, amount);

    vm.prank(admin);
    rupayaBridge.pause();

    vm.prank(user);
    vm.expectRevert();
    rupayaBridge.deposit{value: amount}();
}

function testPausedMint() public {
    uint256 amount = 1 ether;

    vm.prank(admin);
    binanceBridge.pause();

    vm.prank(minter);
    vm.expectRevert();
    binanceBridge.mint(user, amount);
}

    function testSetMaxTransferAmount() public {
        uint256 newMaxAmount = 2000 ether;

        vm.prank(admin);
        rupayaBridge.setMaxTransferAmount(newMaxAmount);
        assertEq(rupayaBridge.maxTransferAmount(), newMaxAmount);

        vm.prank(admin);
        binanceBridge.setMaxTransferAmount(newMaxAmount);
        assertEq(binanceBridge.maxTransferAmount(), newMaxAmount);
    }

    function testSetTransferCooldown() public {
        uint256 newCooldown = 2 hours;

        vm.prank(admin);
        rupayaBridge.setTransferCooldown(newCooldown);
        assertEq(rupayaBridge.transferCooldown(), newCooldown);

        vm.prank(admin);
        binanceBridge.setTransferCooldown(newCooldown);
        assertEq(binanceBridge.transferCooldown(), newCooldown);
    }

    function testUnauthorizedSetMaxTransferAmount() public {
        uint256 newMaxAmount = 2000 ether;

        vm.prank(user);
        vm.expectRevert();
        rupayaBridge.setMaxTransferAmount(newMaxAmount);

        vm.prank(user);
        vm.expectRevert();
        binanceBridge.setMaxTransferAmount(newMaxAmount);
    }

    function testUnauthorizedSetTransferCooldown() public {
        uint256 newCooldown = 2 hours;

        vm.prank(user);
        vm.expectRevert();
        rupayaBridge.setTransferCooldown(newCooldown);

        vm.prank(user);
        vm.expectRevert();
        binanceBridge.setTransferCooldown(newCooldown);
    }
}