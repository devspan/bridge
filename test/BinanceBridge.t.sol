// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/BinanceBridge.sol";

contract BinanceBridgeTest is Test {
    BinanceBridge public bridge;
    address public admin = address(1);
    address public user = address(2);
    address public minter = address(3);
    uint256 public constant INITIAL_MAX_TRANSFER_AMOUNT = 1000 ether;
    uint256 public constant INITIAL_TRANSFER_COOLDOWN = 1 hours;

    event MaxTransferAmountUpdated(uint256 newAmount, uint256 timestamp);
    event TransferCooldownUpdated(uint256 newCooldown, uint256 timestamp);

    function setUp() public {
        vm.startPrank(admin);
        bridge = new BinanceBridge(INITIAL_MAX_TRANSFER_AMOUNT, INITIAL_TRANSFER_COOLDOWN);
        bridge.grantRole(bridge.MINTER_ROLE(), minter);
        bridge.grantRole(bridge.PAUSER_ROLE(), admin);
        vm.stopPrank();
    }

    function testMint() public {
        uint256 amount = 100 ether;

        vm.prank(minter);
        bridge.mint(user, amount);

        assertEq(bridge.balanceOf(user), amount);
    }

    function testBurn() public {
        uint256 amount = 100 ether;

        vm.prank(minter);
        bridge.mint(user, amount);

        vm.warp(block.timestamp + bridge.transferCooldown());

        vm.prank(user);
        bridge.burn(amount);

        assertEq(bridge.balanceOf(user), 0);
    }

    function testPause() public {
        vm.prank(admin);
        bridge.pause();

        vm.expectRevert();
        vm.prank(minter);
        bridge.mint(user, 1 ether);
    }

    function testUnpause() public {
        vm.startPrank(admin);
        bridge.pause();
        bridge.unpause();
        vm.stopPrank();

        vm.prank(minter);
        bridge.mint(user, 1 ether);

        assertEq(bridge.balanceOf(user), 1 ether);
    }

    function testMintExceedingMaxAmount() public {
        uint256 maxAmount = bridge.maxTransferAmount();
        uint256 exceedingAmount = maxAmount + 1 ether;

        vm.prank(minter);
        vm.expectRevert("Amount exceeds maximum transfer limit");
        bridge.mint(user, exceedingAmount);
    }

    function testBurnExceedingMaxAmount() public {
        uint256 maxAmount = bridge.maxTransferAmount();
        uint256 exceedingAmount = maxAmount + 1 ether;

        vm.prank(minter);
        bridge.mint(user, maxAmount);

        vm.warp(block.timestamp + bridge.transferCooldown());

        vm.prank(user);
        vm.expectRevert("Amount exceeds maximum transfer limit");
        bridge.burn(exceedingAmount);
    }

    function testNonMinterMint() public {
        vm.prank(user);
        vm.expectRevert();
        bridge.mint(user, 1 ether);
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

    function testBurnMoreThanBalance() public {
        uint256 mintAmount = 1 ether;
        uint256 burnAmount = 2 ether;

        vm.prank(minter);
        bridge.mint(user, mintAmount);

        vm.warp(block.timestamp + bridge.transferCooldown());

        vm.prank(user);
        vm.expectRevert("ERC20: burn amount exceeds balance");
        bridge.burn(burnAmount);
    }

    function testBurnWithinCooldown() public {
        uint256 amount = 1 ether;

        vm.prank(minter);
        bridge.mint(user, amount);

        vm.prank(user);
        vm.expectRevert("Transfer cooldown not met");
        bridge.burn(amount);
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

    function testTransfer() public {
        uint256 amount = 100 ether;
        address recipient = address(4);

        vm.prank(minter);
        bridge.mint(user, amount);

        vm.prank(user);
        bool success = bridge.transfer(recipient, amount);

        assertTrue(success);
        assertEq(bridge.balanceOf(recipient), amount);
        assertEq(bridge.balanceOf(user), 0);
    }

    function testTransferFrom() public {
        uint256 amount = 100 ether;
        address recipient = address(4);

        vm.prank(minter);
        bridge.mint(user, amount);

        vm.prank(user);
        bridge.approve(address(this), amount);

        bool success = bridge.transferFrom(user, recipient, amount);

        assertTrue(success);
        assertEq(bridge.balanceOf(recipient), amount);
        assertEq(bridge.balanceOf(user), 0);
    }

    function testPausedTransfer() public {
        uint256 amount = 100 ether;
        address recipient = address(4);

        vm.prank(minter);
        bridge.mint(user, amount);

        vm.prank(admin);
        bridge.pause();

        vm.prank(user);
        vm.expectRevert();
        bridge.transfer(recipient, amount);
    }

    function testPausedTransferFrom() public {
        uint256 amount = 100 ether;
        address recipient = address(4);

        vm.prank(minter);
        bridge.mint(user, amount);

        vm.prank(user);
        bridge.approve(address(this), amount);

        vm.prank(admin);
        bridge.pause();

        vm.expectRevert();
        bridge.transferFrom(user, recipient, amount);
    }
}