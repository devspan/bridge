// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/BinanceBridge.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract BinanceBridgeTest is Test {
    BinanceBridge public bridge;
    address public admin = address(1);
    address public user = address(2);
    address public nonAdmin = address(3);

    function setUp() public {
        vm.startPrank(admin);
        bridge = new BinanceBridge();
        vm.stopPrank();
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

        // Warp time to bypass the transfer cooldown
        vm.warp(block.timestamp + bridge.TRANSFER_COOLDOWN());

        vm.prank(user);
        bridge.burn(amount);

        assertEq(bridge.balanceOf(user), 0);
    }

    function testPause() public {
        vm.prank(admin);
        bridge.pause();

        vm.startPrank(admin);
        vm.expectRevert(Pausable.EnforcedPause.selector);
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

    function testMintExceedingMaxAmount() public {
        uint256 maxAmount = bridge.MAX_TRANSFER_AMOUNT();
        uint256 exceedingAmount = maxAmount + 1 ether;

        vm.prank(admin);
        vm.expectRevert("Amount exceeds maximum transfer limit");
        bridge.mint(user, exceedingAmount);
    }

    function testBurnExceedingMaxAmount() public {
        uint256 maxAmount = bridge.MAX_TRANSFER_AMOUNT();
        uint256 exceedingAmount = maxAmount + 1 ether;

        // First, mint the maximum amount
        vm.prank(admin);
        bridge.mint(user, maxAmount);

        // Warp time to bypass the transfer cooldown
        vm.warp(block.timestamp + bridge.TRANSFER_COOLDOWN());

        // Now try to burn more than the maximum
        vm.prank(user);
        vm.expectRevert("Amount exceeds maximum transfer limit");
        bridge.burn(exceedingAmount);
    }

    function testNonAdminMint() public {
        vm.prank(nonAdmin);
        vm.expectRevert();
        bridge.mint(user, 1 ether);
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

    function testBurnMoreThanBalance() public {
        uint256 mintAmount = 1 ether;
        uint256 burnAmount = 2 ether;

        vm.prank(admin);
        bridge.mint(user, mintAmount);

        // Warp time to bypass the transfer cooldown
        vm.warp(block.timestamp + bridge.TRANSFER_COOLDOWN());

        vm.prank(user);
        vm.expectRevert("ERC20: burn amount exceeds balance");
        bridge.burn(burnAmount);
    }

    function testBurnWithinCooldown() public {
        uint256 amount = 1 ether;

        vm.prank(admin);
        bridge.mint(user, amount);

        vm.prank(user);
        vm.expectRevert("Transfer cooldown not met");
        bridge.burn(amount);
    }
}